const std = @import("std");

/// Variant type classification
pub const VariantType = enum {
    pseudo_class,
    pseudo_element,
    media_query,
    attribute,
    state,
    responsive,
    dark_mode,
    group,
    peer,
    container,
};

/// Variant definition
pub const VariantDef = struct {
    name: []const u8,
    type: VariantType,
    css: []const u8,
};

/// All pseudo-class variants
pub const pseudo_class_variants = std.StaticStringMap([]const u8).initComptime(.{
    // Mouse interaction
    .{ "hover", ":hover" },
    .{ "active", ":active" },

    // Focus states
    .{ "focus", ":focus" },
    .{ "focus-visible", ":focus-visible" },
    .{ "focus-within", ":focus-within" },

    // Link states
    .{ "visited", ":visited" },
    .{ "target", ":target" },

    // Form states
    .{ "disabled", ":disabled" },
    .{ "enabled", ":enabled" },
    .{ "checked", ":checked" },
    .{ "indeterminate", ":indeterminate" },
    .{ "default", ":default" },
    .{ "required", ":required" },
    .{ "valid", ":valid" },
    .{ "invalid", ":invalid" },
    .{ "in-range", ":in-range" },
    .{ "out-of-range", ":out-of-range" },
    .{ "placeholder-shown", ":placeholder-shown" },
    .{ "autofill", ":autofill" },
    .{ "read-only", ":read-only" },

    // Structural pseudo-classes
    .{ "first", ":first-child" },
    .{ "last", ":last-child" },
    .{ "only", ":only-child" },
    .{ "odd", ":nth-child(odd)" },
    .{ "even", ":nth-child(even)" },
    .{ "first-of-type", ":first-of-type" },
    .{ "last-of-type", ":last-of-type" },
    .{ "only-of-type", ":only-of-type" },
    .{ "empty", ":empty" },

    // State variants (dialog)
    .{ "open", ":open" },

    // Modern pseudo-classes
    .{ "has", ":has" },
    .{ "is", ":is" },
    .{ "where", ":where" },
    .{ "not", ":not" },
});

/// All pseudo-element variants
pub const pseudo_element_variants = std.StaticStringMap([]const u8).initComptime(.{
    .{ "before", "::before" },
    .{ "after", "::after" },
    .{ "first-letter", "::first-letter" },
    .{ "first-line", "::first-line" },
    .{ "marker", "::marker" },
    .{ "selection", "::selection" },
    .{ "file", "::file-selector-button" },
    .{ "backdrop", "::backdrop" },
    .{ "placeholder", "::placeholder" },
});

/// Media query variants
pub const media_query_variants = std.StaticStringMap([]const u8).initComptime(.{
    .{ "motion-safe", "@media (prefers-reduced-motion: no-preference)" },
    .{ "motion-reduce", "@media (prefers-reduced-motion: reduce)" },
    .{ "contrast-more", "@media (prefers-contrast: more)" },
    .{ "contrast-less", "@media (prefers-contrast: less)" },
    .{ "print", "@media print" },
    .{ "portrait", "@media (orientation: portrait)" },
    .{ "landscape", "@media (orientation: landscape)" },
});

/// Responsive breakpoints (default Tailwind breakpoints)
pub const responsive_breakpoints = std.StaticStringMap([]const u8).initComptime(.{
    .{ "sm", "@media (min-width: 640px)" },
    .{ "md", "@media (min-width: 768px)" },
    .{ "lg", "@media (min-width: 1024px)" },
    .{ "xl", "@media (min-width: 1280px)" },
    .{ "2xl", "@media (min-width: 1536px)" },
});

/// Max-width breakpoints
pub const max_breakpoints = std.StaticStringMap([]const u8).initComptime(.{
    .{ "max-sm", "@media (max-width: 639px)" },
    .{ "max-md", "@media (max-width: 767px)" },
    .{ "max-lg", "@media (max-width: 1023px)" },
    .{ "max-xl", "@media (max-width: 1279px)" },
    .{ "max-2xl", "@media (max-width: 1535px)" },
});

/// ARIA attribute variants
pub const aria_variants = [_][]const u8{
    "aria-checked",
    "aria-disabled",
    "aria-expanded",
    "aria-hidden",
    "aria-pressed",
    "aria-readonly",
    "aria-required",
    "aria-selected",
};

/// Data attribute variants
pub const data_variants = [_][]const u8{
    "data-active",
    "data-disabled",
    "data-open",
    "data-closed",
    "data-highlighted",
};

/// Get CSS for a variant
pub fn getVariantCSS(variant: []const u8) ?VariantDef {
    // Check pseudo-classes
    if (pseudo_class_variants.get(variant)) |css| {
        return VariantDef{
            .name = variant,
            .type = .pseudo_class,
            .css = css,
        };
    }

    // Check pseudo-elements
    if (pseudo_element_variants.get(variant)) |css| {
        return VariantDef{
            .name = variant,
            .type = .pseudo_element,
            .css = css,
        };
    }

    // Check responsive breakpoints
    if (responsive_breakpoints.get(variant)) |css| {
        return VariantDef{
            .name = variant,
            .type = .responsive,
            .css = css,
        };
    }

    // Check max-width breakpoints
    if (max_breakpoints.get(variant)) |css| {
        return VariantDef{
            .name = variant,
            .type = .responsive,
            .css = css,
        };
    }

    // Check media queries
    if (media_query_variants.get(variant)) |css| {
        return VariantDef{
            .name = variant,
            .type = .media_query,
            .css = css,
        };
    }

    // Check for dark mode
    if (std.mem.eql(u8, variant, "dark")) {
        return VariantDef{
            .name = "dark",
            .type = .dark_mode,
            .css = ".dark", // Will be used as parent selector
        };
    }

    // Check for group variants
    if (std.mem.startsWith(u8, variant, "group-")) {
        return VariantDef{
            .name = variant,
            .type = .group,
            .css = variant, // Will be processed specially
        };
    }

    // Check for peer variants
    if (std.mem.startsWith(u8, variant, "peer-")) {
        return VariantDef{
            .name = variant,
            .type = .peer,
            .css = variant, // Will be processed specially
        };
    }

    // Check for ARIA attributes
    for (aria_variants) |aria_variant| {
        if (std.mem.eql(u8, variant, aria_variant)) {
            return VariantDef{
                .name = variant,
                .type = .attribute,
                .css = variant,
            };
        }
    }

    // Check for data attributes
    for (data_variants) |data_variant| {
        if (std.mem.eql(u8, variant, data_variant)) {
            return VariantDef{
                .name = variant,
                .type = .attribute,
                .css = variant,
            };
        }
    }

    return null;
}

/// Check if variant is a responsive breakpoint
pub fn isResponsiveVariant(variant: []const u8) bool {
    return responsive_breakpoints.has(variant) or max_breakpoints.has(variant);
}

/// Check if variant is a pseudo-class
pub fn isPseudoClass(variant: []const u8) bool {
    return pseudo_class_variants.has(variant);
}

/// Check if variant is a pseudo-element
pub fn isPseudoElement(variant: []const u8) bool {
    return pseudo_element_variants.has(variant);
}

/// Check if variant is a media query
pub fn isMediaQuery(variant: []const u8) bool {
    return media_query_variants.has(variant);
}

test "getVariantCSS pseudo-class" {
    const hover = getVariantCSS("hover");
    try std.testing.expect(hover != null);
    try std.testing.expectEqual(VariantType.pseudo_class, hover.?.type);
    try std.testing.expectEqualStrings(":hover", hover.?.css);
}

test "getVariantCSS pseudo-element" {
    const before = getVariantCSS("before");
    try std.testing.expect(before != null);
    try std.testing.expectEqual(VariantType.pseudo_element, before.?.type);
    try std.testing.expectEqualStrings("::before", before.?.css);
}

test "getVariantCSS responsive" {
    const md = getVariantCSS("md");
    try std.testing.expect(md != null);
    try std.testing.expectEqual(VariantType.responsive, md.?.type);
    try std.testing.expectEqualStrings("@media (min-width: 768px)", md.?.css);
}

test "getVariantCSS dark mode" {
    const dark = getVariantCSS("dark");
    try std.testing.expect(dark != null);
    try std.testing.expectEqual(VariantType.dark_mode, dark.?.type);
}
