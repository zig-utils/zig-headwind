const std = @import("std");
const types = @import("../core/types.zig");
const string_utils = @import("../utils/string.zig");
const class_parser = @import("../parser/class_parser.zig");

/// CSS Rule builder
pub const CSSRule = struct {
    selector: []const u8,
    declarations: std.StringHashMap([]const u8),
    media: ?[]const u8 = null,
    pseudo: ?[]const u8 = null,
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
        if (self.pseudo) |p| allocator.free(p);
    }

    pub fn addDeclaration(self: *CSSRule, allocator: std.mem.Allocator, property: []const u8, value: []const u8) !void {
        const prop = try allocator.dupe(u8, property);
        const val = try allocator.dupe(u8, value);
        try self.declarations.put(prop, val);
    }

    pub fn toString(self: *const CSSRule, allocator: std.mem.Allocator) ![]const u8 {
        var result = string_utils.StringBuilder.init(allocator);
        errdefer result.deinit();

        // Build selector with pseudo-classes
        const full_selector = if (self.pseudo) |pseudo| blk: {
            var sel = string_utils.StringBuilder.init(allocator);
            defer sel.deinit();
            try sel.append(self.selector);
            try sel.append(pseudo);
            break :blk try sel.toOwnedSlice();
        } else try allocator.dupe(u8, self.selector);
        defer if (self.pseudo != null) allocator.free(full_selector);

        // Wrap in media query if needed
        if (self.media) |media| {
            try result.append(media);
            try result.append(" {\n  ");
        }

        // Selector
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

        if (self.media) |_| {
            try result.append("\n}");
        }

        return result.toOwnedSlice();
    }
};

/// CSS Generator for utility classes
pub const CSSGenerator = struct {
    allocator: std.mem.Allocator,
    rules: std.ArrayList(CSSRule),

    pub fn init(allocator: std.mem.Allocator) CSSGenerator {
        return .{
            .allocator = allocator,
            .rules = std.ArrayList(CSSRule){},
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
        const utility_name = utility_parts.name;

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
        } else if (std.mem.startsWith(u8, utility_name, "w")) {
            try self.generateWidth(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "h")) {
            try self.generateHeight(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "text")) {
            try self.generateText(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "font")) {
            try self.generateFont(parsed, utility_parts.value);
        } else if (std.mem.startsWith(u8, utility_name, "bg")) {
            // Check if it's a gradient utility
            if (utility_parts.value) |val| {
                if (std.mem.startsWith(u8, val, "gradient")) {
                    // bg-gradient-to-r -> extract "to-r"
                    const gradient_part = val[9..]; // Skip "gradient-"
                    try self.generateBackgroundGradient(parsed, gradient_part);
                } else {
                    try self.generateBackground(parsed, utility_parts.value);
                }
            } else {
                try self.generateBackground(parsed, utility_parts.value);
            }
        } else if (std.mem.startsWith(u8, utility_name, "border")) {
            try self.generateBorder(parsed, utility_parts.value);
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
            try self.generateScrollBehavior(parsed, utility_parts.value);
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

    pub fn createRule(self: *CSSGenerator, parsed: *const class_parser.ParsedClass) !CSSRule {
        // Build selector
        var selector = string_utils.StringBuilder.init(self.allocator);
        defer selector.deinit();

        try selector.append(".");
        try selector.append(parsed.raw);

        var rule = try CSSRule.init(self.allocator, selector.toString());
        rule.is_important = parsed.is_important;

        // Apply variants (media queries, pseudo-classes, etc.)
        for (parsed.variants) |variant| {
            try self.applyVariant(&rule, variant);
        }

        return rule;
    }

    fn applyVariant(self: *CSSGenerator, rule: *CSSRule, variant: []const u8) !void {
        const variants_module = @import("variants.zig");

        const variant_def = variants_module.getVariantCSS(variant) orelse return;

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
            .dark_mode => {
                // Dark mode uses a parent selector
                if (rule.pseudo) |existing| {
                    const combined = try std.fmt.allocPrint(
                        self.allocator,
                        ".dark {s}",
                        .{existing},
                    );
                    self.allocator.free(existing);
                    rule.pseudo = combined;
                } else {
                    rule.pseudo = try self.allocator.dupe(u8, ".dark ");
                }
            },
            .group => {
                // Group variants like group-hover
                const state = variant[6..]; // Remove "group-" prefix
                if (variants_module.pseudo_class_variants.get(state)) |pseudo| {
                    const group_selector = try std.fmt.allocPrint(
                        self.allocator,
                        ".group{s} ",
                        .{pseudo},
                    );
                    if (rule.pseudo) |existing| {
                        const combined = try std.fmt.allocPrint(
                            self.allocator,
                            "{s}{s}",
                            .{ group_selector, existing },
                        );
                        self.allocator.free(group_selector);
                        self.allocator.free(existing);
                        rule.pseudo = combined;
                    } else {
                        rule.pseudo = group_selector;
                    }
                }
            },
            .peer => {
                // Peer variants like peer-checked
                const state = variant[5..]; // Remove "peer-" prefix
                if (variants_module.pseudo_class_variants.get(state)) |pseudo| {
                    const peer_selector = try std.fmt.allocPrint(
                        self.allocator,
                        ".peer{s} ~ ",
                        .{pseudo},
                    );
                    if (rule.pseudo) |existing| {
                        const combined = try std.fmt.allocPrint(
                            self.allocator,
                            "{s}{s}",
                            .{ peer_selector, existing },
                        );
                        self.allocator.free(peer_selector);
                        self.allocator.free(existing);
                        rule.pseudo = combined;
                    } else {
                        rule.pseudo = peer_selector;
                    }
                }
            },
            .attribute => {
                // ARIA and data attributes
                const attr_selector = try std.fmt.allocPrint(
                    self.allocator,
                    "[{s}]",
                    .{variant},
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
            .state, .container => {
                // Not yet implemented
            },
        }
    }

    /// Generate all CSS rules as a string
    pub fn generate(self: *CSSGenerator) ![]const u8 {
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

    fn generateBackground(self: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
        return colors.generateBackground(self, parsed, value);
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
