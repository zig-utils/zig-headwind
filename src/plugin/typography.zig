const std = @import("std");
const plugin = @import("plugin.zig");
const PluginContext = plugin.PluginContext;
const StyleDeclaration = plugin.StyleDeclaration;

/// Typography plugin - adds prose classes for beautiful typography
pub fn typographyPlugin(ctx: *PluginContext) !void {
    // Add prose base styles
    try ctx.addComponents(".prose", &.{
        StyleDeclaration{ .property = "color", .value = "#374151" },
        StyleDeclaration{ .property = "max-width", .value = "65ch" },
        StyleDeclaration{ .property = "font-size", .value = "1rem" },
        StyleDeclaration{ .property = "line-height", .value = "1.75" },
    });

    // Prose headings
    try ctx.addComponents(".prose h1", &.{
        StyleDeclaration{ .property = "color", .value = "#111827" },
        StyleDeclaration{ .property = "font-weight", .value = "800" },
        StyleDeclaration{ .property = "font-size", .value = "2.25em" },
        StyleDeclaration{ .property = "margin-top", .value = "0" },
        StyleDeclaration{ .property = "margin-bottom", .value = "0.8888889em" },
        StyleDeclaration{ .property = "line-height", .value = "1.1111111" },
    });

    try ctx.addComponents(".prose h2", &.{
        StyleDeclaration{ .property = "color", .value = "#111827" },
        StyleDeclaration{ .property = "font-weight", .value = "700" },
        StyleDeclaration{ .property = "font-size", .value = "1.5em" },
        StyleDeclaration{ .property = "margin-top", .value = "2em" },
        StyleDeclaration{ .property = "margin-bottom", .value = "1em" },
        StyleDeclaration{ .property = "line-height", .value = "1.3333333" },
    });

    try ctx.addComponents(".prose h3", &.{
        StyleDeclaration{ .property = "color", .value = "#111827" },
        StyleDeclaration{ .property = "font-weight", .value = "600" },
        StyleDeclaration{ .property = "font-size", .value = "1.25em" },
        StyleDeclaration{ .property = "margin-top", .value = "1.6em" },
        StyleDeclaration{ .property = "margin-bottom", .value = "0.6em" },
        StyleDeclaration{ .property = "line-height", .value = "1.6" },
    });

    // Prose paragraphs
    try ctx.addComponents(".prose p", &.{
        StyleDeclaration{ .property = "margin-top", .value = "1.25em" },
        StyleDeclaration{ .property = "margin-bottom", .value = "1.25em" },
    });

    // Prose links
    try ctx.addComponents(".prose a", &.{
        StyleDeclaration{ .property = "color", .value = "#3b82f6" },
        StyleDeclaration{ .property = "text-decoration", .value = "underline" },
        StyleDeclaration{ .property = "font-weight", .value = "500" },
    });

    try ctx.addComponents(".prose a:hover", &.{
        StyleDeclaration{ .property = "color", .value = "#2563eb" },
    });

    // Prose strong
    try ctx.addComponents(".prose strong", &.{
        StyleDeclaration{ .property = "color", .value = "#111827" },
        StyleDeclaration{ .property = "font-weight", .value = "600" },
    });

    // Prose code
    try ctx.addComponents(".prose code", &.{
        StyleDeclaration{ .property = "color", .value = "#111827" },
        StyleDeclaration{ .property = "font-weight", .value = "600" },
        StyleDeclaration{ .property = "font-size", .value = "0.875em" },
        StyleDeclaration{ .property = "background-color", .value = "#f3f4f6" },
        StyleDeclaration{ .property = "padding", .value = "0.2em 0.4em" },
        StyleDeclaration{ .property = "border-radius", .value = "0.25rem" },
    });

    // Prose pre
    try ctx.addComponents(".prose pre", &.{
        StyleDeclaration{ .property = "color", .value = "#e5e7eb" },
        StyleDeclaration{ .property = "background-color", .value = "#1f2937" },
        StyleDeclaration{ .property = "overflow-x", .value = "auto" },
        StyleDeclaration{ .property = "font-size", .value = "0.875em" },
        StyleDeclaration{ .property = "line-height", .value = "1.7142857" },
        StyleDeclaration{ .property = "margin-top", .value = "1.7142857em" },
        StyleDeclaration{ .property = "margin-bottom", .value = "1.7142857em" },
        StyleDeclaration{ .property = "border-radius", .value = "0.375rem" },
        StyleDeclaration{ .property = "padding", .value = "0.8571429em 1.1428571em" },
    });

    try ctx.addComponents(".prose pre code", &.{
        StyleDeclaration{ .property = "background-color", .value = "transparent" },
        StyleDeclaration{ .property = "border-width", .value = "0" },
        StyleDeclaration{ .property = "border-radius", .value = "0" },
        StyleDeclaration{ .property = "padding", .value = "0" },
        StyleDeclaration{ .property = "font-weight", .value = "inherit" },
        StyleDeclaration{ .property = "color", .value = "inherit" },
        StyleDeclaration{ .property = "font-size", .value = "inherit" },
    });

    // Prose lists
    try ctx.addComponents(".prose ul", &.{
        StyleDeclaration{ .property = "list-style-type", .value = "disc" },
        StyleDeclaration{ .property = "margin-top", .value = "1.25em" },
        StyleDeclaration{ .property = "margin-bottom", .value = "1.25em" },
        StyleDeclaration{ .property = "padding-left", .value = "1.625em" },
    });

    try ctx.addComponents(".prose ol", &.{
        StyleDeclaration{ .property = "list-style-type", .value = "decimal" },
        StyleDeclaration{ .property = "margin-top", .value = "1.25em" },
        StyleDeclaration{ .property = "margin-bottom", .value = "1.25em" },
        StyleDeclaration{ .property = "padding-left", .value = "1.625em" },
    });

    try ctx.addComponents(".prose li", &.{
        StyleDeclaration{ .property = "margin-top", .value = "0.5em" },
        StyleDeclaration{ .property = "margin-bottom", .value = "0.5em" },
    });

    // Prose blockquote
    try ctx.addComponents(".prose blockquote", &.{
        StyleDeclaration{ .property = "font-weight", .value = "500" },
        StyleDeclaration{ .property = "font-style", .value = "italic" },
        StyleDeclaration{ .property = "color", .value = "#111827" },
        StyleDeclaration{ .property = "border-left-width", .value = "0.25rem" },
        StyleDeclaration{ .property = "border-left-color", .value = "#e5e7eb" },
        StyleDeclaration{ .property = "quotes", .value = "\"\\201C\"\"\\201D\"\"\\2018\"\"\\2019\"" },
        StyleDeclaration{ .property = "margin-top", .value = "1.6em" },
        StyleDeclaration{ .property = "margin-bottom", .value = "1.6em" },
        StyleDeclaration{ .property = "padding-left", .value = "1em" },
    });

    // Prose hr
    try ctx.addComponents(".prose hr", &.{
        StyleDeclaration{ .property = "border-color", .value = "#e5e7eb" },
        StyleDeclaration{ .property = "border-top-width", .value = "1px" },
        StyleDeclaration{ .property = "margin-top", .value = "3em" },
        StyleDeclaration{ .property = "margin-bottom", .value = "3em" },
    });

    // Prose table
    try ctx.addComponents(".prose table", &.{
        StyleDeclaration{ .property = "width", .value = "100%" },
        StyleDeclaration{ .property = "table-layout", .value = "auto" },
        StyleDeclaration{ .property = "text-align", .value = "left" },
        StyleDeclaration{ .property = "margin-top", .value = "2em" },
        StyleDeclaration{ .property = "margin-bottom", .value = "2em" },
        StyleDeclaration{ .property = "font-size", .value = "0.875em" },
        StyleDeclaration{ .property = "line-height", .value = "1.7142857" },
    });

    try ctx.addComponents(".prose thead", &.{
        StyleDeclaration{ .property = "border-bottom-width", .value = "1px" },
        StyleDeclaration{ .property = "border-bottom-color", .value = "#d1d5db" },
    });

    try ctx.addComponents(".prose thead th", &.{
        StyleDeclaration{ .property = "color", .value = "#111827" },
        StyleDeclaration{ .property = "font-weight", .value = "600" },
        StyleDeclaration{ .property = "vertical-align", .value = "bottom" },
        StyleDeclaration{ .property = "padding-right", .value = "0.5714286em" },
        StyleDeclaration{ .property = "padding-bottom", .value = "0.5714286em" },
        StyleDeclaration{ .property = "padding-left", .value = "0.5714286em" },
    });

    try ctx.addComponents(".prose tbody tr", &.{
        StyleDeclaration{ .property = "border-bottom-width", .value = "1px" },
        StyleDeclaration{ .property = "border-bottom-color", .value = "#e5e7eb" },
    });

    try ctx.addComponents(".prose tbody td", &.{
        StyleDeclaration{ .property = "vertical-align", .value = "baseline" },
        StyleDeclaration{ .property = "padding", .value = "0.5714286em" },
    });

    // Prose img
    try ctx.addComponents(".prose img", &.{
        StyleDeclaration{ .property = "margin-top", .value = "2em" },
        StyleDeclaration{ .property = "margin-bottom", .value = "2em" },
    });

    // Size variants
    try ctx.addComponents(".prose-sm", &.{
        StyleDeclaration{ .property = "font-size", .value = "0.875rem" },
        StyleDeclaration{ .property = "line-height", .value = "1.7142857" },
    });

    try ctx.addComponents(".prose-lg", &.{
        StyleDeclaration{ .property = "font-size", .value = "1.125rem" },
        StyleDeclaration{ .property = "line-height", .value = "1.7777778" },
    });

    try ctx.addComponents(".prose-xl", &.{
        StyleDeclaration{ .property = "font-size", .value = "1.25rem" },
        StyleDeclaration{ .property = "line-height", .value = "1.8" },
    });
}
