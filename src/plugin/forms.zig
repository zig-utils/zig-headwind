const std = @import("std");
const plugin = @import("plugin.zig");
const PluginContext = plugin.PluginContext;
const StyleDeclaration = plugin.StyleDeclaration;

/// Forms plugin - adds beautiful form styles
pub fn formsPlugin(ctx: *PluginContext) !void {
    // Base form input styles
    try ctx.addBase("[type='text'], [type='email'], [type='url'], [type='password'], [type='number'], [type='date'], [type='datetime-local'], [type='month'], [type='search'], [type='tel'], [type='time'], [type='week'], [multiple], textarea, select", &.{
        StyleDeclaration{ .property = "appearance", .value = "none" },
        StyleDeclaration{ .property = "background-color", .value = "#fff" },
        StyleDeclaration{ .property = "border-color", .value = "#6b7280" },
        StyleDeclaration{ .property = "border-width", .value = "1px" },
        StyleDeclaration{ .property = "border-radius", .value = "0" },
        StyleDeclaration{ .property = "padding-top", .value = "0.5rem" },
        StyleDeclaration{ .property = "padding-right", .value = "0.75rem" },
        StyleDeclaration{ .property = "padding-bottom", .value = "0.5rem" },
        StyleDeclaration{ .property = "padding-left", .value = "0.75rem" },
        StyleDeclaration{ .property = "font-size", .value = "1rem" },
        StyleDeclaration{ .property = "line-height", .value = "1.5rem" },
    });

    // Input focus states
    try ctx.addBase("[type='text']:focus, [type='email']:focus, [type='url']:focus, [type='password']:focus, [type='number']:focus, [type='date']:focus, [type='datetime-local']:focus, [type='month']:focus, [type='search']:focus, [type='tel']:focus, [type='time']:focus, [type='week']:focus, [multiple]:focus, textarea:focus, select:focus", &.{
        StyleDeclaration{ .property = "outline", .value = "2px solid transparent" },
        StyleDeclaration{ .property = "outline-offset", .value = "2px" },
        StyleDeclaration{ .property = "box-shadow", .value = "0 0 0 1px #3b82f6, 0 0 0 4px rgba(59, 130, 246, 0.1)" },
        StyleDeclaration{ .property = "border-color", .value = "#3b82f6" },
    });

    // Input placeholder
    try ctx.addBase("[type='text']::placeholder, [type='email']::placeholder, [type='url']::placeholder, [type='password']::placeholder, [type='number']::placeholder, [type='date']::placeholder, [type='datetime-local']::placeholder, [type='month']::placeholder, [type='search']::placeholder, [type='tel']::placeholder, [type='time']::placeholder, [type='week']::placeholder, textarea::placeholder", &.{
        StyleDeclaration{ .property = "color", .value = "#6b7280" },
        StyleDeclaration{ .property = "opacity", .value = "1" },
    });

    // Select
    try ctx.addBase("select", &.{
        StyleDeclaration{ .property = "background-image", .value = "url(\"data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e\")" },
        StyleDeclaration{ .property = "background-position", .value = "right 0.5rem center" },
        StyleDeclaration{ .property = "background-repeat", .value = "no-repeat" },
        StyleDeclaration{ .property = "background-size", .value = "1.5em 1.5em" },
        StyleDeclaration{ .property = "padding-right", .value = "2.5rem" },
        StyleDeclaration{ .property = "print-color-adjust", .value = "exact" },
    });

    // Checkbox and radio
    try ctx.addBase("[type='checkbox'], [type='radio']", &.{
        StyleDeclaration{ .property = "appearance", .value = "none" },
        StyleDeclaration{ .property = "padding", .value = "0" },
        StyleDeclaration{ .property = "print-color-adjust", .value = "exact" },
        StyleDeclaration{ .property = "display", .value = "inline-block" },
        StyleDeclaration{ .property = "vertical-align", .value = "middle" },
        StyleDeclaration{ .property = "background-origin", .value = "border-box" },
        StyleDeclaration{ .property = "user-select", .value = "none" },
        StyleDeclaration{ .property = "flex-shrink", .value = "0" },
        StyleDeclaration{ .property = "height", .value = "1rem" },
        StyleDeclaration{ .property = "width", .value = "1rem" },
        StyleDeclaration{ .property = "color", .value = "#3b82f6" },
        StyleDeclaration{ .property = "background-color", .value = "#fff" },
        StyleDeclaration{ .property = "border-color", .value = "#6b7280" },
        StyleDeclaration{ .property = "border-width", .value = "1px" },
    });

    // Checkbox
    try ctx.addBase("[type='checkbox']", &.{
        StyleDeclaration{ .property = "border-radius", .value = "0" },
    });

    // Radio
    try ctx.addBase("[type='radio']", &.{
        StyleDeclaration{ .property = "border-radius", .value = "100%" },
    });

    // Checkbox/radio focus
    try ctx.addBase("[type='checkbox']:focus, [type='radio']:focus", &.{
        StyleDeclaration{ .property = "outline", .value = "2px solid transparent" },
        StyleDeclaration{ .property = "outline-offset", .value = "2px" },
        StyleDeclaration{ .property = "box-shadow", .value = "0 0 0 2px #fff, 0 0 0 4px #3b82f6" },
    });

    // Checkbox checked
    try ctx.addBase("[type='checkbox']:checked", &.{
        StyleDeclaration{ .property = "border-color", .value = "transparent" },
        StyleDeclaration{ .property = "background-color", .value = "currentColor" },
        StyleDeclaration{ .property = "background-size", .value = "100% 100%" },
        StyleDeclaration{ .property = "background-position", .value = "center" },
        StyleDeclaration{ .property = "background-repeat", .value = "no-repeat" },
        StyleDeclaration{ .property = "background-image", .value = "url(\"data:image/svg+xml,%3csvg viewBox='0 0 16 16' fill='white' xmlns='http://www.w3.org/2000/svg'%3e%3cpath d='M12.207 4.793a1 1 0 010 1.414l-5 5a1 1 0 01-1.414 0l-2-2a1 1 0 011.414-1.414L6.5 9.086l4.293-4.293a1 1 0 011.414 0z'/%3e%3c/svg%3e\")" },
    });

    // Radio checked
    try ctx.addBase("[type='radio']:checked", &.{
        StyleDeclaration{ .property = "border-color", .value = "transparent" },
        StyleDeclaration{ .property = "background-color", .value = "currentColor" },
        StyleDeclaration{ .property = "background-size", .value = "100% 100%" },
        StyleDeclaration{ .property = "background-position", .value = "center" },
        StyleDeclaration{ .property = "background-repeat", .value = "no-repeat" },
        StyleDeclaration{ .property = "background-image", .value = "url(\"data:image/svg+xml,%3csvg viewBox='0 0 16 16' fill='white' xmlns='http://www.w3.org/2000/svg'%3e%3ccircle cx='8' cy='8' r='3'/%3e%3c/svg%3e\")" },
    });

    // Indeterminate checkbox
    try ctx.addBase("[type='checkbox']:indeterminate", &.{
        StyleDeclaration{ .property = "background-image", .value = "url(\"data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 16 16'%3e%3cpath stroke='white' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M4 8h8'/%3e%3c/svg%3e\")" },
        StyleDeclaration{ .property = "border-color", .value = "transparent" },
        StyleDeclaration{ .property = "background-color", .value = "currentColor" },
        StyleDeclaration{ .property = "background-size", .value = "100% 100%" },
        StyleDeclaration{ .property = "background-position", .value = "center" },
        StyleDeclaration{ .property = "background-repeat", .value = "no-repeat" },
    });

    // File input
    try ctx.addBase("[type='file']", &.{
        StyleDeclaration{ .property = "background", .value = "unset" },
        StyleDeclaration{ .property = "border-color", .value = "inherit" },
        StyleDeclaration{ .property = "border-width", .value = "0" },
        StyleDeclaration{ .property = "border-radius", .value = "0" },
        StyleDeclaration{ .property = "padding", .value = "0" },
        StyleDeclaration{ .property = "font-size", .value = "unset" },
        StyleDeclaration{ .property = "line-height", .value = "inherit" },
    });

    try ctx.addBase("[type='file']:focus", &.{
        StyleDeclaration{ .property = "outline", .value = "1px solid ButtonText" },
        StyleDeclaration{ .property = "outline", .value = "1px auto -webkit-focus-ring-color" },
    });
}
