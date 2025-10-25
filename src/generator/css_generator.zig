const std = @import("std");
const types = @import("../core/types.zig");
const string_utils = @import("../utils/string.zig");
const class_parser = @import("../parser/class_parser.zig");

/// CSS Rule builder
pub const CSSRule = struct {
    selector: []const u8,
    declarations: std.StringHashMap([]const u8),
    media: ?[]const u8 = null,
    container: ?[]const u8 = null, // For container queries
    pseudo: ?[]const u8 = null,
    parent_selector: ?[]const u8 = null, // For group/peer variants
    is_important: bool = false,

    pub fn init(allocator: std.mem.Allocator, selector: []const u8) !CSSRule {
        return .{
            .selector = try allocator.dupe(u8, selector),
            .declarations = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *CSSRule, allocator: std.mem.Allocator) void {
        allocator.free(self.selector);
        var iter = self.declarations.iterator();
        while (iter.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            allocator.free(entry.value_ptr.*);
        }
        self.declarations.deinit();
        if (self.media) |m| allocator.free(m);
        if (self.container) |c| allocator.free(c);
        if (self.pseudo) |p| allocator.free(p);
        if (self.parent_selector) |ps| allocator.free(ps);
    }

    pub fn addDeclaration(self: *CSSRule, allocator: std.mem.Allocator, property: []const u8, value: []const u8) !void {
        const prop = try allocator.dupe(u8, property);
        const val = try allocator.dupe(u8, value);
        try self.declarations.put(prop, val);
    }

    /// Add a declaration taking ownership of the value (useful for allocPrint results)
    pub fn addDeclarationOwned(self: *CSSRule, allocator: std.mem.Allocator, property: []const u8, value: []const u8) !void {
        const prop = try allocator.dupe(u8, property);
        try self.declarations.put(prop, value);
    }

    pub fn toString(self: *const CSSRule, allocator: std.mem.Allocator) ![]const u8 {
        var result = string_utils.StringBuilder.init(allocator);
        errdefer result.deinit();

        // Build selector with parent selector (for group/peer) and pseudo-classes
        var needs_free = false;
        const full_selector = if (self.parent_selector) |parent| blk: {
            var sel = string_utils.StringBuilder.init(allocator);
            defer sel.deinit();
            try sel.append(parent);
            try sel.append(self.selector);
            if (self.pseudo) |pseudo| {
                try sel.append(pseudo);
            }
            needs_free = true;
            break :blk try sel.toOwnedSlice();
        } else if (self.pseudo) |pseudo| blk: {
            var sel = string_utils.StringBuilder.init(allocator);
            defer sel.deinit();
            try sel.append(self.selector);
            try sel.append(pseudo);
            needs_free = true;
            break :blk try sel.toOwnedSlice();
        } else blk: {
            needs_free = true;
            break :blk try allocator.dupe(u8, self.selector);
        };
        defer if (needs_free) allocator.free(full_selector);

        // Wrap in media query if needed
        if (self.media) |media| {
            try result.append(media);
            try result.append(" {\n  ");
        }

        // Wrap in container query if needed (can be nested with media)
        if (self.container) |container| {
            if (self.media != null) try result.append("  "); // Indent for nested query
            try result.append(container);
            try result.append(" {\n  ");
            if (self.media != null) try result.append("  "); // Extra indent for double nesting
        }

        // Selector
        if (self.container != null and self.media != null) try result.append("  "); // Extra indent
        try result.append(full_selector);
        try result.append(" { ");

        // Declarations
        var iter = self.declarations.iterator();
        var first = true;
        while (iter.next()) |entry| {
            if (!first) try result.append("; ");
            try result.append(entry.key_ptr.*);
            try result.append(": ");
            try result.append(entry.value_ptr.*);
            if (self.is_important) try result.append(" !important");
            first = false;
        }

        try result.append(" }");

        // Close container query wrapper
        if (self.container) |_| {
            try result.append("\n");
            if (self.media != null) try result.append("  "); // Indent for nested query
            try result.append("}");
        }

        // Close media query wrapper
        if (self.media) |_| {
            try result.append("\n}");
        }

        return result.toOwnedSlice();
    }
};

/// Helper function to check if a value looks like a color
/// Returns true for color names with shades (e.g., "blue-500") or single color names (e.g., "white")
fn isColorValue(value: []const u8) bool {
    // Check for color-shade pattern (e.g., "blue-500")
    if (std.mem.indexOf(u8, value, "-")) |_| {
        // Has a dash, likely a color with shade
        const colors = @import("colors.zig").colors;
        var i: usize = value.len;
        while (i > 0) {
            i -= 1;
            if (value[i] == '-') {
                const color_part = value[0..i];
                return colors.has(color_part);
            }
        }
        return false;
    }
    // Check for single color names (white, black)
    const colors = @import("colors.zig").colors;
    return colors.has(value);
}

/// CSS Generator for utility classes
pub const CSSGenerator = struct {
    allocator: std.mem.Allocator,
    rules: std.ArrayList(CSSRule),
    dark_mode_selector: []const u8,
    dark_mode_strategy: DarkModeStrategy,

    pub const DarkModeStrategy = enum {
        @"class",
        media,
    };

    pub const Config = struct {
        dark_mode_selector: []const u8 = "dark",
        dark_mode_strategy: DarkModeStrategy = .@"class",
    };

    pub fn init(allocator: std.mem.Allocator) CSSGenerator {
        return initWithConfig(allocator, .{});
    }

    pub fn initWithConfig(allocator: std.mem.Allocator, config: Config) CSSGenerator {
        return .{
            .allocator = allocator,
            .rules = .{},
            .dark_mode_selector = config.dark_mode_selector,
            .dark_mode_strategy = config.dark_mode_strategy,
        };
    }

    pub fn deinit(self: *CSSGenerator) void {
        for (self.rules.items) |*rule| {
            rule.deinit(self.allocator);
        }
        self.rules.deinit(self.allocator);
    }

    /// Generate CSS for a class name
    pub fn generateForClass(self: *CSSGenerator, class_name: []const u8) !void {
        // Parse the class
        var parsed = class_parser.parseClass(self.allocator, class_name) catch {
            // If parsing fails, skip this class
            return;
        };
        defer parsed.deinit(self.allocator);

        // Generate CSS rule based on utility
        try self.generateUtility(&parsed);
    }

    /// Generate utility CSS based on parsed class
    fn generateUtility(self: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
        const utility_parts = class_parser.parseUtility(parsed.utility);
        var utility_name = utility_parts.name;

        // Handle negative margins: "-m-4" becomes name="-m", we want to match on "m"
        const is_negative_margin = std.mem.startsWith(u8, utility_name, "-m");
        if (is_negative_margin) {
            // Call generateMargin directly for negative margins
            try self.generateMargin(parsed, utility_parts.value);
            return;
        }

        // Dispatch to appropriate utility generator
        if (std.mem.eql(u8, utility_name, "flex")) {
            try self.generateFlex(parsed);
        } else if (std.mem.eql(u8, utility_name, "block")) {
            try self.generateDisplay(parsed, "block");
        } else if (std.mem.eql(u8, utility_name, "inline")) {
            try self.generateDisplay(parsed, "inline");
        } else if (std.mem.eql(u8, utility_name, "hidden")) {
            try self.generateDisplay(parsed, "none");
        } else if (std.mem.eql(u8, utility_name, "grid")) {
            try self.generateDisplay(parsed, "grid");
        } else if (std.mem.startsWith(u8, utility_name, "container")) {
            // container, container-type, container-name
            if (std.mem.eql(u8, utility_name, "container-type")) {
                try self.generateContainerType(parsed, utility_parts.value);
            } else if (std.mem.eql(u8, utility_name, "container-name")) {
                try self.generateContainerName(parsed, utility_parts.value);
            } else if (std.mem.eql(u8, utility_name, "container")) {
                try self.generateContainer(parsed);
            } else {
                // container-normal, container-size - these set container-type
                try self.generateContainerTypeValue(parsed, utility_parts.value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "overflow")) {
            try self.generateOverflowUtility(parsed, utility_parts);
        } else if (std.mem.eql(u8, utility_name, "visible")) {
            try self.generateVisibilityUtility(parsed, "visible");
        } else if (std.mem.eql(u8, utility_name, "invisible")) {
            try self.generateVisibilityUtility(parsed, "invisible");
        } else if (std.mem.eql(u8, utility_name, "collapse")) {
            try self.generateVisibilityUtility(parsed, "collapse");
        } else if (std.mem.eql(u8, utility_name, "z")) {
            try self.generateZIndexUtility(parsed, utility_parts.value);
        } else if (std.mem.eql(u8, utility_name, "isolate")) {
            try self.generateIsolationUtility(parsed, "isolate");
        } else if (std.mem.eql(u8, utility_name, "isolation")) {
            // isolation-auto -> value = "auto"
            if (utility_parts.value) |val| {
                try self.generateIsolationUtility(parsed, val);
            }
        } else if (std.mem.eql(u8, utility_name, "object")) {
            try self.generateObjectUtility(parsed, utility_parts);
        } else if (std.mem.startsWith(u8, utility_name, "items")) {
            try self.generateAlignItems(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "justify")) {
            try self.generateJustifyContent(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "p")) {
            try self.generatePadding(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "m")) {
            try self.generateMargin(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "gap")) {
            try self.generateGap(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "whitespace")) {
            try self.generateWhitespace(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "hyphens")) {
            try self.generateHyphens(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "w")) {
            try self.generateWidth(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "h")) {
            try self.generateHeight(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "text")) {
            // Check for text-wrap utilities first
            if (utility_parts.value) |val| {
                if (std.mem.eql(u8, val, "wrap") or std.mem.eql(u8, val, "nowrap") or
                    std.mem.eql(u8, val, "balance") or std.mem.eql(u8, val, "pretty")) {
                    try self.generateTextWrap(parsed);
                    return; // Early return to avoid further checks
                }
            }
            // text-shadow-sm, text-oklch-[...], text-color-mix-[...], etc.
            if (std.mem.startsWith(u8, utility_name, "text-shadow")) {
                // text-shadow-sm -> value="sm"
                const shadow_value = if (std.mem.eql(u8, utility_name, "text-shadow")) null else utility_parts.value;
                try self.generateTextShadow(parsed, shadow_value);
            } else if (utility_parts.value) |val| {
                if (std.mem.startsWith(u8, val, "oklch-")) {
                    // text-oklch-[0.5_0.2_180]
                    const oklch_value = val[6..]; // Skip "oklch-"
                    try self.generateOklchText(parsed, oklch_value);
                } else if (std.mem.startsWith(u8, val, "color-mix-")) {
                    // text-color-mix-[in_srgb,_blue_50%,_red]
                    const mix_value = val[10..]; // Skip "color-mix-"
                    try self.generateColorMixText(parsed, mix_value);
                } else if (parsed.is_arbitrary or isColorValue(val)) {
                    // text-[rgb(255,0,0)] or text-blue-500
                    try self.generateTextColor(parsed, utility_parts.value);
                } else {
                    // text-sm, text-left, etc.
                    try self.generateText(parsed, utility_parts.value);
                }
            } else {
                try self.generateText(parsed, utility_parts.value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "font")) {
            try self.generateFont(parsed, utility_parts.value);
        } else if (std.mem.eql(u8, utility_name, "italic") or std.mem.eql(u8, utility_name, "not-italic")) {
            try self.generateFontStyle(parsed);
        } else if (std.mem.eql(u8, utility_name, "underline") or std.mem.eql(u8, utility_name, "overline") or
                   std.mem.eql(u8, utility_name, "line-through") or std.mem.eql(u8, utility_name, "no-underline")) {
            try self.generateTextDecoration(parsed);
        } else if (std.mem.eql(u8, utility_name, "uppercase") or std.mem.eql(u8, utility_name, "lowercase") or
                   std.mem.eql(u8, utility_name, "capitalize") or std.mem.eql(u8, utility_name, "normal-case")) {
            try self.generateTextTransform(parsed);
        } else if (std.mem.eql(u8, utility_name, "truncate") or std.mem.eql(u8, utility_name, "text-ellipsis") or
                   std.mem.eql(u8, utility_name, "text-clip")) {
            try self.generateTextOverflow(parsed);
        } else if (std.mem.startsWith(u8, utility_name, "leading")) {
            try self.generateLineHeight(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "tracking")) {
            try self.generateLetterSpacing(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "indent")) {
            try self.generateTextIndent(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "align")) {
            try self.generateVerticalAlign(parsed, utility_parts.value);
        } else if (std.mem.eql(u8, utility_name, "break")) {
            if (utility_parts.value) |val| {
                if (std.mem.eql(u8, val, "normal") or std.mem.eql(u8, val, "words") or
                    std.mem.eql(u8, val, "all") or std.mem.eql(u8, val, "keep")) {
                    try self.generateWordBreak(parsed);
                }
            }
        } else if (std.mem.startsWith(u8, utility_name, "bg")) {
            // Check for special background utilities
            if (utility_parts.value) |val| {
                if (std.mem.startsWith(u8, val, "gradient")) {
                    // bg-gradient-to-r -> extract "to-r"
                    const gradient_part = val[9..]; // Skip "gradient-"
                    try self.generateBackgroundGradient(parsed, gradient_part);
                } else if (std.mem.startsWith(u8, val, "oklch-")) {
                    // bg-oklch-[0.5_0.2_180]
                    const oklch_value = val[6..]; // Skip "oklch-"
                    try self.generateOklchBackground(parsed, oklch_value);
                } else if (std.mem.startsWith(u8, val, "color-mix-")) {
                    // bg-color-mix-[in_srgb,_blue_50%,_red]
                    const mix_value = val[10..]; // Skip "color-mix-"
                    try self.generateColorMixBackground(parsed, mix_value);
                } else if (std.mem.startsWith(u8, val, "fixed") or std.mem.startsWith(u8, val, "local") or std.mem.startsWith(u8, val, "scroll")) {
                    // bg-fixed, bg-local, bg-scroll
                    try self.generateBackgroundAttachment(parsed, val);
                } else if (std.mem.startsWith(u8, val, "clip-")) {
                    // bg-clip-border, bg-clip-padding, bg-clip-content, bg-clip-text
                    const clip_value = val[5..]; // Skip "clip-"
                    try self.generateBackgroundClip(parsed, clip_value);
                } else if (std.mem.startsWith(u8, val, "origin-")) {
                    // bg-origin-border, bg-origin-padding, bg-origin-content
                    const origin_value = val[7..]; // Skip "origin-"
                    try self.generateBackgroundOrigin(parsed, origin_value);
                } else if (std.mem.startsWith(u8, val, "repeat") or std.mem.startsWith(u8, val, "no-repeat")) {
                    // bg-repeat, bg-no-repeat, bg-repeat-x, bg-repeat-y, bg-repeat-round, bg-repeat-space
                    try self.generateBackgroundRepeat(parsed, val);
                } else if (std.mem.startsWith(u8, val, "auto") or std.mem.startsWith(u8, val, "cover") or std.mem.startsWith(u8, val, "contain")) {
                    // bg-auto, bg-cover, bg-contain
                    try self.generateBackgroundSize(parsed, val);
                } else if (std.mem.startsWith(u8, val, "bottom") or std.mem.startsWith(u8, val, "center") or
                           std.mem.startsWith(u8, val, "left") or std.mem.startsWith(u8, val, "right") or
                           std.mem.startsWith(u8, val, "top")) {
                    // bg-bottom, bg-center, bg-left, bg-left-bottom, bg-left-top, bg-right, etc.
                    try self.generateBackgroundPosition(parsed, val);
                } else {
                    try self.generateBackground(parsed, utility_parts.value);
                }
            } else {
                try self.generateBackground(parsed, utility_parts.value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "border")) {
            // Check if it's a border color
            if (utility_parts.value) |val| {
                if (parsed.is_arbitrary or isColorValue(val)) {
                    // border-[#00ff00] or border-blue-500
                    try self.generateBorderColor(parsed, utility_parts.value);
                } else {
                    // border-2, border-t, etc. (width)
                    try self.generateBorder(parsed, utility_parts.value);
                }
            } else {
                try self.generateBorder(parsed, utility_parts.value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "rounded")) {
            try self.generateBorderRadius(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "from")) {
            try self.generateGradientFrom(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "via")) {
            try self.generateGradientVia(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "to")) {
            try self.generateGradientTo(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "scale")) {
            if (std.mem.indexOf(u8, utility_name, "-x")) |_| {
                try self.generateScaleX(parsed, utility_parts.value);
            } else if (std.mem.indexOf(u8, utility_name, "-y")) |_| {
                try self.generateScaleY(parsed, utility_parts.value);
            } else {
                try self.generateScale(parsed, utility_parts.value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "rotate")) {
            try self.generateRotate(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "translate")) {
            if (std.mem.indexOf(u8, utility_name, "-x")) |_| {
                try self.generateTranslateX(parsed, utility_parts.value);
            } else if (std.mem.indexOf(u8, utility_name, "-y")) |_| {
                try self.generateTranslateY(parsed, utility_parts.value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "skew")) {
            if (std.mem.indexOf(u8, utility_name, "-x")) |_| {
                try self.generateSkewX(parsed, utility_parts.value);
            } else if (std.mem.indexOf(u8, utility_name, "-y")) |_| {
                try self.generateSkewY(parsed, utility_parts.value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "origin")) {
            try self.generateOrigin(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "transform-")) {
            // transform-flat, transform-preserve-3d
            if (std.mem.indexOf(u8, utility_name, "transform-")) |_| {
                const style_value = utility_name[10..]; // Skip "transform-"
                try self.generateTransformStyle(parsed, style_value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "perspective")) {
            // perspective-500, perspective-origin-center
            if (std.mem.startsWith(u8, utility_name, "perspective-origin")) {
                const origin_value = utility_parts.value;
                try self.generatePerspectiveOrigin(parsed, origin_value);
            } else {
                try self.generatePerspective(parsed, utility_parts.value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "backface-")) {
            // backface-visible, backface-hidden
            const visibility_value = utility_name[9..]; // Skip "backface-"
            try self.generateBackfaceVisibility(parsed, visibility_value);
        } else if (std.mem.startsWith(u8, utility_name, "animate-")) {
            // animate-iteration-*, animate-direction-*, etc.
            if (std.mem.indexOf(u8, utility_name, "iteration")) |_| {
                try self.generateAnimationIterationCount(parsed, utility_parts.value);
            } else if (std.mem.indexOf(u8, utility_name, "direction")) |_| {
                try self.generateAnimationDirection(parsed, utility_parts.value);
            } else if (std.mem.indexOf(u8, utility_name, "fill")) |_| {
                try self.generateAnimationFillMode(parsed, utility_parts.value);
            } else if (std.mem.indexOf(u8, utility_name, "play")) |_| {
                try self.generateAnimationPlayState(parsed, utility_parts.value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "blur")) {
            try self.generateBlur(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "brightness")) {
            try self.generateBrightness(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "contrast")) {
            try self.generateContrast(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "grayscale")) {
            try self.generateGrayscale(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "hue-rotate")) {
            try self.generateHueRotate(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "invert")) {
            try self.generateInvert(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "saturate")) {
            try self.generateSaturate(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "sepia")) {
            try self.generateSepia(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "drop-shadow")) {
            try self.generateDropShadow(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "backdrop-blur")) {
            try self.generateBackdropBlur(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "backdrop-brightness")) {
            try self.generateBackdropBrightness(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "backdrop-contrast")) {
            try self.generateBackdropContrast(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "backdrop-grayscale")) {
            try self.generateBackdropGrayscale(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "shadow")) {
            try self.generateShadow(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "transition")) {
            try self.generateTransition(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "duration")) {
            try self.generateDuration(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "ease")) {
            try self.generateEase(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "delay")) {
            try self.generateDelay(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "animate")) {
            try self.generateAnimate(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "cursor")) {
            try self.generateCursor(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "pointer-events")) {
            try self.generatePointerEvents(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "resize")) {
            try self.generateResize(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "scroll")) {
            try self.dispatchScrollUtility(parsed, utility_name, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "snap")) {
            try self.dispatchSnapUtility(parsed, utility_name, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "touch")) {
            try self.generateTouchAction(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "select")) {
            try self.generateSelect(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "appearance")) {
            try self.generateAppearance(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "caret")) {
            try self.generateCaretColor(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "accent")) {
            try self.generateAccentColor(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "will-change")) {
            try self.generateWillChange(parsed, utility_parts.value);
        }
        // More utilities will be added...
    }

    fn generateFlex(self: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
        var rule = try self.createRule(parsed);
        try rule.addDeclaration(self.allocator, "display", "flex");
        try self.rules.append(self.allocator, rule);
    }

    fn generateDisplay(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: []const u8) !void {
        var rule = try self.createRule(parsed);
        try rule.addDeclaration(self.allocator, "display", value);
        try self.rules.append(self.allocator, rule);
    }

    fn generateAlignItems(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        if (value == null) return;
        const css_value = if (std.mem.eql(u8, value.?, "center"))
            "center"
        else if (std.mem.eql(u8, value.?, "start"))
            "flex-start"
        else if (std.mem.eql(u8, value.?, "end"))
            "flex-end"
        else if (std.mem.eql(u8, value.?, "baseline"))
            "baseline"
        else if (std.mem.eql(u8, value.?, "stretch"))
            "stretch"
        else
            return;

        var rule = try self.createRule(parsed);
        try rule.addDeclaration(self.allocator, "align-items", css_value);
        try self.rules.append(self.allocator, rule);
    }

    fn generateJustifyContent(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        if (value == null) return;
        const css_value = if (std.mem.eql(u8, value.?, "center"))
            "center"
        else if (std.mem.eql(u8, value.?, "between"))
            "space-between"
        else if (std.mem.eql(u8, value.?, "around"))
            "space-around"
        else if (std.mem.eql(u8, value.?, "evenly"))
            "space-evenly"
        else if (std.mem.eql(u8, value.?, "start"))
            "flex-start"
        else if (std.mem.eql(u8, value.?, "end"))
            "flex-end"
        else
            return;

        var rule = try self.createRule(parsed);
        try rule.addDeclaration(self.allocator, "justify-content", css_value);
        try self.rules.append(self.allocator, rule);
    }

    /// Escape special characters in CSS selector
    fn escapeSelector(builder: *string_utils.StringBuilder, raw: []const u8) !void {
        for (raw, 0..) |char, i| {
            // Escape characters that need escaping in CSS selectors
            // Leading dash, brackets, colons, slashes, etc.
            switch (char) {
                '-' => {
                    // Check if this is the first character (needs escaping)
                    if (i == 0) {
                        try builder.append("\\");
                    }
                    try builder.appendChar(char);
                },
                '[', ']', '/', ':', '!', '%', '.', '#', ' ', '(', ')' => {
                    try builder.append("\\");
                    try builder.appendChar(char);
                },
                else => try builder.appendChar(char),
            }
        }
    }

    pub fn createRule(self: *CSSGenerator, parsed: *const class_parser.ParsedClass) !CSSRule {
        // Build selector
        var selector = string_utils.StringBuilder.init(self.allocator);
        defer selector.deinit();

        try selector.append(".");
        // Escape special characters in selector (e.g., leading dash for negative margins)
        try escapeSelector(&selector, parsed.raw);

        var rule = try CSSRule.init(self.allocator, selector.toString());
        rule.is_important = parsed.is_important;

        // Apply variants (media queries, pseudo-classes, etc.)
        for (parsed.variants) |variant_info| {
            try self.applyVariant(&rule, variant_info);
        }

        // Don't append to self.rules here - let the caller do it
        return rule;
    }

    /// Helper declaration struct for addUtility
    pub const Declaration = struct {
        property: []const u8,
        value: []const u8,
    };

    /// Helper method for compatibility with existing layout code
    pub fn addUtility(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, declarations: []const Declaration) !void {
        var rule = try self.createRule(parsed);
        for (declarations) |decl| {
            try rule.addDeclaration(self.allocator, decl.property, decl.value);
        }
        try self.rules.append(self.allocator, rule);
    }

    fn applyVariant(self: *CSSGenerator, rule: *CSSRule, variant_info: class_parser.VariantInfo) !void {
        const variants_module = @import("variants.zig");

        const variant_def = variants_module.getVariantCSS(variant_info.variant) orelse return;

        switch (variant_def.type) {
            .pseudo_class, .pseudo_element => {
                // Append to existing pseudo if there is one (for stacking like hover:focus)
                if (rule.pseudo) |existing| {
                    const combined = try std.fmt.allocPrint(
                        self.allocator,
                        "{s}{s}",
                        .{ existing, variant_def.css },
                    );
                    self.allocator.free(existing);
                    rule.pseudo = combined;
                } else {
                    rule.pseudo = try self.allocator.dupe(u8, variant_def.css);
                }
            },
            .responsive, .media_query => {
                // Media queries wrap the entire rule
                if (rule.media) |existing| {
                    // For now, just use the new one (later we can support nested media queries)
                    self.allocator.free(existing);
                }
                rule.media = try self.allocator.dupe(u8, variant_def.css);
            },
            .container => {
                // Container queries wrap the entire rule (can be nested with media queries)
                if (rule.container) |existing| {
                    // For now, just use the new one
                    self.allocator.free(existing);
                }
                rule.container = try self.allocator.dupe(u8, variant_def.css);
            },
            .dark_mode => {
                // Dark mode: use configured strategy
                switch (self.dark_mode_strategy) {
                    .@"class" => {
                        // Class strategy: use parent selector
                        const selector_prefix = try std.fmt.allocPrint(
                            self.allocator,
                            ".{s} ",
                            .{self.dark_mode_selector},
                        );
                        defer self.allocator.free(selector_prefix);

                        if (rule.pseudo) |existing| {
                            const combined = try std.fmt.allocPrint(
                                self.allocator,
                                "{s}{s}",
                                .{ selector_prefix, existing },
                            );
                            self.allocator.free(existing);
                            rule.pseudo = combined;
                        } else {
                            rule.pseudo = try self.allocator.dupe(u8, selector_prefix);
                        }
                    },
                    .media => {
                        // Media strategy: use media query
                        const media_query = "@media (prefers-color-scheme: dark)";
                        if (rule.media) |existing| {
                            // Already has a media query, would need to nest (complex, skip for now)
                            self.allocator.free(existing);
                        }
                        rule.media = try self.allocator.dupe(u8, media_query);
                    },
                }
            },
            .group => {
                // Group variants: either "group-hover" (unnamed) or "group-hover/sidebar" (named)
                // Check if this is a state variant (e.g., "group-hover")
                if (std.mem.startsWith(u8, variant_info.variant, "group-")) {
                    const state = variant_info.variant[6..]; // Remove "group-" prefix
                    if (variants_module.pseudo_class_variants.get(state)) |pseudo| {
                        // Build the group class name
                        const group_class_name = if (variant_info.name) |name|
                            // Named group: "group/sidebar" -> ".group\\/sidebar"
                            try std.fmt.allocPrint(self.allocator, ".group\\/{s}", .{name})
                        else
                            // Unnamed group: ".group"
                            ".group";
                        defer if (variant_info.name != null) self.allocator.free(group_class_name);

                        const group_selector = try std.fmt.allocPrint(
                            self.allocator,
                            "{s}{s} ",
                            .{ group_class_name, pseudo },
                        );
                        if (rule.parent_selector) |existing| {
                            const combined = try std.fmt.allocPrint(
                                self.allocator,
                                "{s}{s}",
                                .{ existing, group_selector },
                            );
                            self.allocator.free(group_selector);
                            self.allocator.free(existing);
                            rule.parent_selector = combined;
                        } else {
                            rule.parent_selector = group_selector;
                        }
                    }
                } else if (std.mem.eql(u8, variant_info.variant, "group")) {
                    // Just "group" without a state - this is for marking an element as a group parent
                    // We don't generate CSS for this, it's just a marker class
                }
            },
            .peer => {
                // Peer variants: either "peer-checked" (unnamed) or "peer-checked/label" (named)
                // Check if this is a state variant (e.g., "peer-checked")
                if (std.mem.startsWith(u8, variant_info.variant, "peer-")) {
                    const state = variant_info.variant[5..]; // Remove "peer-" prefix
                    if (variants_module.pseudo_class_variants.get(state)) |pseudo| {
                        // Build the peer class name
                        const peer_class_name = if (variant_info.name) |name|
                            // Named peer: "peer/label" -> ".peer\\/label"
                            try std.fmt.allocPrint(self.allocator, ".peer\\/{s}", .{name})
                        else
                            // Unnamed peer: ".peer"
                            ".peer";
                        defer if (variant_info.name != null) self.allocator.free(peer_class_name);

                        const peer_selector = try std.fmt.allocPrint(
                            self.allocator,
                            "{s}{s} ~ ",
                            .{ peer_class_name, pseudo },
                        );
                        if (rule.parent_selector) |existing| {
                            const combined = try std.fmt.allocPrint(
                                self.allocator,
                                "{s}{s}",
                                .{ existing, peer_selector },
                            );
                            self.allocator.free(peer_selector);
                            self.allocator.free(existing);
                            rule.parent_selector = combined;
                        } else {
                            rule.parent_selector = peer_selector;
                        }
                    }
                } else if (std.mem.eql(u8, variant_info.variant, "peer")) {
                    // Just "peer" without a state - this is for marking an element as a peer parent
                    // We don't generate CSS for this, it's just a marker class
                }
            },
            .attribute => {
                // ARIA and data attributes
                const attr_selector = try std.fmt.allocPrint(
                    self.allocator,
                    "[{s}]",
                    .{variant_info.variant},
                );
                if (rule.pseudo) |existing| {
                    const combined = try std.fmt.allocPrint(
                        self.allocator,
                        "{s}{s}",
                        .{ attr_selector, existing },
                    );
                    self.allocator.free(attr_selector);
                    self.allocator.free(existing);
                    rule.pseudo = combined;
                } else {
                    rule.pseudo = attr_selector;
                }
            },
            .state => {
                // Not yet implemented
            },
        }
    }

    /// Generate all CSS rules as a string
    pub fn generate(self: *CSSGenerator) ![]const u8 {
        // Remove duplicate rules
        try self.removeDuplicates();

        // Sort rules for deterministic output
        const ordering = @import("css_ordering.zig");
        ordering.sortRules(self.rules.items);

        var result = string_utils.StringBuilder.init(self.allocator);
        errdefer result.deinit();

        for (self.rules.items) |*rule| {
            const rule_str = try rule.toString(self.allocator);
            defer self.allocator.free(rule_str);
            try result.append(rule_str);
            try result.append("\n");
        }

        return result.toOwnedSlice();
    }

    /// Remove duplicate CSS rules based on selector, media, and pseudo
    fn removeDuplicates(self: *CSSGenerator) !void {
        if (self.rules.items.len == 0) return;

        var seen = std.StringHashMap(void).init(self.allocator);
        defer {
            // Free all the keys we allocated
            var iter = seen.keyIterator();
            while (iter.next()) |key| {
                self.allocator.free(key.*);
            }
            seen.deinit();
        }

        var write_index: usize = 0;
        for (self.rules.items, 0..) |*rule, read_index| {
            // Create a unique key for this rule
            const key = try self.getRuleKey(rule);
            defer self.allocator.free(key);

            const gop = try seen.getOrPut(key);
            if (!gop.found_existing) {
                // Keep this rule
                if (write_index != read_index) {
                    self.rules.items[write_index] = self.rules.items[read_index];
                }
                write_index += 1;

                // Store the key for deduplication
                gop.key_ptr.* = try self.allocator.dupe(u8, key);
            } else {
                // Duplicate rule, clean it up
                rule.deinit(self.allocator);
            }
        }

        // Shrink the array
        self.rules.items.len = write_index;
    }

    fn getRuleKey(self: *CSSGenerator, rule: *const CSSRule) ![]const u8 {
        var key = string_utils.StringBuilder.init(self.allocator);
        errdefer key.deinit();

        try key.append(rule.selector);
        try key.append("|");

        if (rule.media) |media| {
            try key.append(media);
        }
        try key.append("|");

        if (rule.pseudo) |pseudo| {
            try key.append(pseudo);
        }
        try key.append("|");

        if (rule.is_important) {
            try key.append("!");
        }

        return key.toOwnedSlice();
    }

    // Import utility modules
    const spacing = @import("spacing.zig");
    const typography = @import("typography.zig");
    const colors = @import("colors.zig");
    const sizing = @import("sizing.zig");
    const borders = @import("borders.zig");
    const gradients = @import("gradients.zig");
    const modern_colors = @import("modern_colors.zig");
    const transforms = @import("transforms.zig");
    const filters = @import("filters.zig");
    const shadows = @import("shadows.zig");
    const transitions = @import("transitions.zig");
    const animations = @import("animations.zig");
    const interactivity = @import("interactivity.zig");

    fn generatePadding(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return spacing.generatePadding(self, parsed, value);
    }

    fn generateMargin(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return spacing.generateMargin(self, parsed, value);
    }

    fn generateGap(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return spacing.generateGap(self, parsed, value);
    }

    fn generateWidth(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return sizing.generateWidth(self, parsed, value);
    }

    fn generateHeight(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return sizing.generateHeight(self, parsed, value);
    }

    fn generateText(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return typography.generateText(self, parsed, value);
    }

    fn generateFont(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return typography.generateFont(self, parsed, value);
    }

    fn generateTextShadow(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return typography.generateTextShadow(self, parsed, value);
    }

    fn generateFontStyle(self: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
        return typography.generateFontStyle(self, parsed);
    }

    fn generateTextDecoration(self: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
        return typography.generateTextDecoration(self, parsed);
    }

    fn generateTextTransform(self: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
        return typography.generateTextTransform(self, parsed);
    }

    fn generateTextOverflow(self: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
        return typography.generateTextOverflow(self, parsed);
    }

    fn generateLineHeight(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return typography.generateLineHeight(self, parsed, value);
    }

    fn generateLetterSpacing(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return typography.generateLetterSpacing(self, parsed, value);
    }

    fn generateWhitespace(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return typography.generateWhitespace(self, parsed, value);
    }

    fn generateTextWrap(self: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
        return typography.generateTextWrap(self, parsed);
    }

    fn generateVerticalAlign(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return typography.generateVerticalAlign(self, parsed, value);
    }

    fn generateWordBreak(self: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
        return typography.generateWordBreak(self, parsed);
    }

    fn generateTextIndent(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return typography.generateTextIndent(self, parsed, value);
    }

    fn generateHyphens(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return typography.generateHyphens(self, parsed, value);
    }

    fn generateBackground(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return colors.generateBackground(self, parsed, value);
    }

    fn generateTextColor(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return colors.generateTextColor(self, parsed, value);
    }

    fn generateBorderColor(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return colors.generateBorderColor(self, parsed, value);
    }

    // Background utilities
    fn generateBackgroundAttachment(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        const backgrounds = @import("backgrounds.zig");
        return backgrounds.generateBackgroundAttachment(self, parsed, value);
    }

    fn generateBackgroundClip(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        const backgrounds = @import("backgrounds.zig");
        return backgrounds.generateBackgroundClip(self, parsed, value);
    }

    fn generateBackgroundOrigin(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        const backgrounds = @import("backgrounds.zig");
        return backgrounds.generateBackgroundOrigin(self, parsed, value);
    }

    fn generateBackgroundPosition(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        const backgrounds = @import("backgrounds.zig");
        return backgrounds.generateBackgroundPosition(self, parsed, value);
    }

    fn generateBackgroundRepeat(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        const backgrounds = @import("backgrounds.zig");
        return backgrounds.generateBackgroundRepeat(self, parsed, value);
    }

    fn generateBackgroundSize(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        const backgrounds = @import("backgrounds.zig");
        return backgrounds.generateBackgroundSize(self, parsed, value);
    }

    // Modern color functions
    fn generateOklchBackground(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return modern_colors.generateOklchBackground(self, parsed, value);
    }

    fn generateOklchText(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return modern_colors.generateOklchText(self, parsed, value);
    }

    fn generateColorMixBackground(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return modern_colors.generateColorMix(self, parsed, value, "background-color");
    }

    fn generateColorMixText(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return modern_colors.generateColorMix(self, parsed, value, "color");
    }

    fn generateBorder(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return borders.generateBorder(self, parsed, value);
    }

    fn generateBorderRadius(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return borders.generateBorderRadius(self, parsed, value);
    }

    fn generateGradientFrom(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return gradients.generateGradientFrom(self, parsed, value);
    }

    fn generateGradientVia(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return gradients.generateGradientVia(self, parsed, value);
    }

    fn generateGradientTo(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return gradients.generateGradientTo(self, parsed, value);
    }

    fn generateBackgroundGradient(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return gradients.generateBackgroundGradient(self, parsed, value);
    }

    // Transform utilities
    fn generateScale(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateScale(self, parsed, value);
    }

    fn generateScaleX(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateScaleX(self, parsed, value);
    }

    fn generateScaleY(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateScaleY(self, parsed, value);
    }

    fn generateRotate(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateRotate(self, parsed, value);
    }

    fn generateTranslateX(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateTranslateX(self, parsed, value);
    }

    fn generateTranslateY(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateTranslateY(self, parsed, value);
    }

    fn generateSkewX(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateSkewX(self, parsed, value);
    }

    fn generateSkewY(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateSkewY(self, parsed, value);
    }

    fn generateOrigin(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateOrigin(self, parsed, value);
    }

    fn generateTransformStyle(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateTransformStyle(self, parsed, value);
    }

    fn generatePerspective(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generatePerspective(self, parsed, value);
    }

    fn generatePerspectiveOrigin(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generatePerspectiveOrigin(self, parsed, value);
    }

    fn generateBackfaceVisibility(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateBackfaceVisibility(self, parsed, value);
    }

    fn generateAnimationIterationCount(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateAnimationIterationCount(self, parsed, value);
    }

    fn generateAnimationDirection(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateAnimationDirection(self, parsed, value);
    }

    fn generateAnimationFillMode(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateAnimationFillMode(self, parsed, value);
    }

    fn generateAnimationPlayState(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transforms.generateAnimationPlayState(self, parsed, value);
    }

    // Filter utilities
    fn generateBlur(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateBlur(self, parsed, value);
    }

    fn generateBrightness(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateBrightness(self, parsed, value);
    }

    fn generateContrast(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateContrast(self, parsed, value);
    }

    fn generateGrayscale(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateGrayscale(self, parsed, value);
    }

    fn generateHueRotate(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateHueRotate(self, parsed, value);
    }

    fn generateInvert(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateInvert(self, parsed, value);
    }

    fn generateSaturate(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateSaturate(self, parsed, value);
    }

    fn generateSepia(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateSepia(self, parsed, value);
    }

    fn generateDropShadow(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateDropShadow(self, parsed, value);
    }

    fn generateBackdropBlur(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateBackdropBlur(self, parsed, value);
    }

    fn generateBackdropBrightness(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateBackdropBrightness(self, parsed, value);
    }

    fn generateBackdropContrast(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateBackdropContrast(self, parsed, value);
    }

    fn generateBackdropGrayscale(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return filters.generateBackdropGrayscale(self, parsed, value);
    }

    // Shadow utilities
    fn generateShadow(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return shadows.generateShadow(self, parsed, value);
    }

    // Transition utilities
    fn generateTransition(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transitions.generateTransition(self, parsed, value);
    }

    fn generateDuration(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transitions.generateDuration(self, parsed, value);
    }

    fn generateEase(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transitions.generateEase(self, parsed, value);
    }

    fn generateDelay(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return transitions.generateDelay(self, parsed, value);
    }

    // Animation utilities
    fn generateAnimate(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return animations.generateAnimate(self, parsed, value);
    }

    // Interactivity utilities
    fn generateCursor(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateCursor(self, parsed, value);
    }

    fn generatePointerEvents(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generatePointerEvents(self, parsed, value);
    }

    fn generateResize(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateResize(self, parsed, value);
    }

    fn generateScrollBehavior(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateScrollBehavior(self, parsed, value);
    }

    fn generateSelect(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateSelect(self, parsed, value);
    }

    fn generateAppearance(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateAppearance(self, parsed, value);
    }

    fn generateCaretColor(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateCaretColor(self, parsed, value);
    }

    fn generateAccentColor(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateAccentColor(self, parsed, value);
    }

    fn generateWillChange(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateWillChange(self, parsed, value);
    }

    fn generateTouchAction(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateTouchAction(self, parsed, value);
    }

    fn generateScrollMargin(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, side: ?[]const u8, value: ?[]const u8) !void {
        return interactivity.generateScrollMargin(self, parsed, side, value);
    }

    fn generateScrollPadding(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, side: ?[]const u8, value: ?[]const u8) !void {
        return interactivity.generateScrollPadding(self, parsed, side, value);
    }

    fn generateScrollSnapType(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateScrollSnapType(self, parsed, value);
    }

    fn generateScrollSnapAlign(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateScrollSnapAlign(self, parsed, value);
    }

    fn generateScrollSnapStop(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return interactivity.generateScrollSnapStop(self, parsed, value);
    }

    // Dispatchers for complex utility types
    fn dispatchScrollUtility(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, utility_name: []const u8, value: ?[]const u8) !void {
        // scroll-m-4 -> scroll-margin
        // scroll-mx-4 -> scroll-margin-x
        // scroll-p-4 -> scroll-padding
        // scroll-px-4 -> scroll-padding-x
        // scroll-auto/scroll-smooth -> scroll-behavior

        if (std.mem.eql(u8, utility_name, "scroll-auto") or std.mem.eql(u8, utility_name, "scroll-smooth")) {
            const behavior_value = if (std.mem.eql(u8, utility_name, "scroll-auto")) "auto" else "smooth";
            return self.generateScrollBehavior(parsed, behavior_value);
        } else if (std.mem.startsWith(u8, utility_name, "scroll-m")) {
            // scroll-m-4, scroll-mx-4, scroll-mt-4, etc.
            const rest = utility_name[8..]; // Skip "scroll-m"
            if (rest.len == 0) {
                return self.generateScrollMargin(parsed, null, value);
            } else if (rest[0] == 'x' or rest[0] == 'y' or rest[0] == 't' or rest[0] == 'r' or rest[0] == 'b' or rest[0] == 'l') {
                const side = rest[0..1];
                return self.generateScrollMargin(parsed, side, value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "scroll-p")) {
            // scroll-p-4, scroll-px-4, scroll-pt-4, etc.
            const rest = utility_name[8..]; // Skip "scroll-p"
            if (rest.len == 0) {
                return self.generateScrollPadding(parsed, null, value);
            } else if (rest[0] == 'x' or rest[0] == 'y' or rest[0] == 't' or rest[0] == 'r' or rest[0] == 'b' or rest[0] == 'l') {
                const side = rest[0..1];
                return self.generateScrollPadding(parsed, side, value);
            }
        }
    }

    fn dispatchSnapUtility(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, utility_name: []const u8, _: ?[]const u8) !void {
        // snap-x, snap-y, snap-both, snap-none -> scroll-snap-type
        // snap-start, snap-center, snap-end -> scroll-snap-align
        // snap-normal, snap-always -> scroll-snap-stop

        if (std.mem.eql(u8, utility_name, "snap-none") or
            std.mem.eql(u8, utility_name, "snap-x") or
            std.mem.eql(u8, utility_name, "snap-y") or
            std.mem.eql(u8, utility_name, "snap-both") or
            std.mem.eql(u8, utility_name, "snap-mandatory") or
            std.mem.eql(u8, utility_name, "snap-proximity")) {
            const snap_value = utility_name[5..]; // Skip "snap-"
            return self.generateScrollSnapType(parsed, snap_value);
        } else if (std.mem.eql(u8, utility_name, "snap-start") or
                   std.mem.eql(u8, utility_name, "snap-end") or
                   std.mem.eql(u8, utility_name, "snap-center")) {
            const align_value = utility_name[5..]; // Skip "snap-"
            return self.generateScrollSnapAlign(parsed, align_value);
        } else if (std.mem.eql(u8, utility_name, "snap-normal") or
                   std.mem.eql(u8, utility_name, "snap-always")) {
            const stop_value = utility_name[5..]; // Skip "snap-"
            return self.generateScrollSnapStop(parsed, stop_value);
        }
    }

    // Layout utility wrappers
    fn generateContainer(self: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
        const layout = @import("layout.zig");
        return layout.generateContainer(self, parsed);
    }

    fn generateContainerType(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        const container = @import("container.zig");
        return container.generateContainerType(self, parsed, value);
    }

    fn generateContainerName(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        const container = @import("container.zig");
        return container.generateContainerName(self, parsed, value);
    }

    fn generateContainerTypeValue(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        const container = @import("container.zig");
        return container.generateContainer(self, parsed, value);
    }

    fn generateOverflowUtility(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, parts: anytype) !void {
        const layout = @import("layout.zig");
        // overflow-x-auto -> axis="x", value="auto"
        // overflow-hidden -> axis=null, value="hidden"
        if (parts.value) |val| {
            if (std.mem.startsWith(u8, val, "x-")) {
                return layout.generateOverflow(self, parsed, "x", val[2..]);
            } else if (std.mem.startsWith(u8, val, "y-")) {
                return layout.generateOverflow(self, parsed, "y", val[2..]);
            } else {
                return layout.generateOverflow(self, parsed, null, val);
            }
        }
    }

    fn generateVisibilityUtility(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: []const u8) !void {
        const layout = @import("layout.zig");
        return layout.generateVisibility(self, parsed, value);
    }

    fn generateZIndexUtility(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        const layout = @import("layout.zig");
        return layout.generateZIndex(self, parsed, value);
    }

    fn generateIsolationUtility(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: []const u8) !void {
        const layout = @import("layout.zig");
        return layout.generateIsolation(self, parsed, value);
    }

    fn generateObjectUtility(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, parts: anytype) !void {
        const layout = @import("layout.zig");
        // object-cover, object-contain, object-fill, etc.
        // object-center, object-top, etc.
        if (parts.value) |val| {
            if (std.mem.eql(u8, val, "cover") or std.mem.eql(u8, val, "contain") or
                std.mem.eql(u8, val, "fill") or std.mem.eql(u8, val, "none") or std.mem.eql(u8, val, "scale-down")) {
                return layout.generateObjectFit(self, parsed, val);
            } else {
                return layout.generateObjectPosition(self, parsed, val);
            }
        }
    }
};

test "CSSRule basic" {
    const allocator = std.testing.allocator;

    var rule = try CSSRule.init(allocator, ".flex");
    defer rule.deinit(allocator);

    try rule.addDeclaration(allocator, "display", "flex");

    const css = try rule.toString(allocator);
    defer allocator.free(css);

    try std.testing.expect(std.mem.indexOf(u8, css, "display: flex") != null);
}

test "CSSGenerator flex" {
    const allocator = std.testing.allocator;

    var generator = CSSGenerator.init(allocator);
    defer generator.deinit();

    try generator.generateForClass("flex");

    const css = try generator.generate();
    defer allocator.free(css);

    try std.testing.expect(css.len > 0);
}
