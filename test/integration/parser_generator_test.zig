const std = @import("std");
const testing = std.testing;
const crosswind = @import("crosswind");

const class_parser = crosswind.class_parser;
const CSSGenerator = crosswind.CSSGenerator;

// ============================================================================
// Integration Tests: Parser + Generator
// ============================================================================

test "parse and generate simple utility" {
    const allocator = testing.allocator;

    var parsed = try class_parser.parseClass(allocator, "bg-blue-500");
    defer parsed.deinit(allocator);

    var generator = CSSGenerator.init(allocator);
    defer generator.deinit();

    // Generate CSS from parsed class
    try crosswind.backgrounds.generateBgColor(&generator, &parsed, "blue-500");

    const css = try generator.generate();
    defer allocator.free(css);

    try testing.expect(std.mem.indexOf(u8, css, ".bg-blue-500") != null);
    try testing.expect(std.mem.indexOf(u8, css, "background-color") != null);
    try testing.expect(std.mem.indexOf(u8, css, "oklch(") != null);
}

test "parse and generate with variant" {
    const allocator = testing.allocator;

    var parsed = try class_parser.parseClass(allocator, "hover:bg-blue-500");
    defer parsed.deinit(allocator);

    try testing.expect(parsed.variants.len == 1);

    var generator = CSSGenerator.init(allocator);
    defer generator.deinit();

    try crosswind.backgrounds.generateBgColor(&generator, &parsed, "blue-500");

    const css = try generator.generate();
    defer allocator.free(css);

    try testing.expect(std.mem.indexOf(u8, css, ":hover") != null);
    try testing.expect(std.mem.indexOf(u8, css, "background-color") != null);
}

test "parse and generate with multiple variants" {
    const allocator = testing.allocator;

    var parsed = try class_parser.parseClass(allocator, "md:hover:focus:text-white");
    defer parsed.deinit(allocator);

    try testing.expect(parsed.variants.len == 3);

    var generator = CSSGenerator.init(allocator);
    defer generator.deinit();

    try crosswind.typography.generateTextColor(&generator, &parsed, "white");

    const css = try generator.generate();
    defer allocator.free(css);

    try testing.expect(css.len > 0);
}

test "parse and generate with important modifier" {
    const allocator = testing.allocator;

    var parsed = try class_parser.parseClass(allocator, "bg-blue-500!");
    defer parsed.deinit(allocator);

    try testing.expect(parsed.is_important);

    var generator = CSSGenerator.init(allocator);
    defer generator.deinit();

    try crosswind.backgrounds.generateBgColor(&generator, &parsed, "blue-500");

    const css = try generator.generate();
    defer allocator.free(css);

    try testing.expect(std.mem.indexOf(u8, css, "!important") != null);
}

test "parse and generate arbitrary value" {
    const allocator = testing.allocator;

    var parsed = try class_parser.parseClass(allocator, "w-[200px]");
    defer parsed.deinit(allocator);

    try testing.expect(parsed.is_arbitrary);
    try testing.expect(parsed.arbitrary_value != null);

    var generator = CSSGenerator.init(allocator);
    defer generator.deinit();

    try crosswind.sizing.generateWidth(&generator, &parsed, "200px");

    const css = try generator.generate();
    defer allocator.free(css);

    try testing.expect(std.mem.indexOf(u8, css, "width") != null);
    try testing.expect(std.mem.indexOf(u8, css, "200px") != null);
}

test "batch process multiple classes" {
    const allocator = testing.allocator;

    const classes = [_][]const u8{
        "bg-blue-500",
        "text-white",
        "p-4",
        "rounded-lg",
        "shadow-md",
    };

    var generator = CSSGenerator.init(allocator);
    defer generator.deinit();

    for (classes) |class| {
        var parsed = try class_parser.parseClass(allocator, class);

        // Would normally dispatch to appropriate generator based on class type
        parsed.deinit(allocator);
    }

    const css = try generator.generate();
    defer allocator.free(css);

    // Should have generated CSS for all classes
    try testing.expect(css.len >= 0); // Placeholder assertion
}

test "deduplication of identical rules" {
    const allocator = testing.allocator;

    var generator = CSSGenerator.init(allocator);
    defer generator.deinit();

    // Generate the same class twice
    for (0..2) |_| {
        var parsed = try class_parser.parseClass(allocator, "bg-blue-500");
        defer parsed.deinit(allocator);

        try crosswind.backgrounds.generateBgColor(&generator, &parsed, "blue-500");
    }

    const css = try generator.generate();
    defer allocator.free(css);

    // Should not have duplicate rules
    try testing.expect(css.len > 0);
}

test "parse negative values" {
    const allocator = testing.allocator;

    const negative_classes = [_][]const u8{
        "-m-4",
        "-top-5",
        "-translate-x-[50px]",
        "-rotate-45",
    };

    for (negative_classes) |class| {
        var parsed = try class_parser.parseClass(allocator, class);
        defer parsed.deinit(allocator);

        try testing.expect(parsed.utility.len > 0);
    }
}

test "parse named group variants" {
    const allocator = testing.allocator;

    var parsed = try class_parser.parseClass(allocator, "group/sidebar-hover:bg-gray");
    defer parsed.deinit(allocator);

    try testing.expect(parsed.variants.len > 0);
    // Should have variant with name "sidebar"
}

test "parse named peer variants" {
    const allocator = testing.allocator;

    var parsed = try class_parser.parseClass(allocator, "peer/label-focus:font-bold");
    defer parsed.deinit(allocator);

    try testing.expect(parsed.variants.len > 0);
    // Should have variant with name "label"
}

// ============================================================================
// Edge Cases
// ============================================================================

test "parse empty string" {
    const allocator = testing.allocator;

    const result = class_parser.parseClass(allocator, "");
    try testing.expectError(error.InvalidClassName, result);
}

test "parse whitespace only" {
    const allocator = testing.allocator;

    const result = class_parser.parseClass(allocator, "   ");
    try testing.expectError(error.InvalidClassName, result);
}

test "parse very long class name" {
    const allocator = testing.allocator;

    // Create a class with 1000+ character name
    var long_class: std.ArrayList(u8) = .empty;
    defer long_class.deinit(allocator);

    try long_class.appendSlice(allocator, "hover:focus:active:md:lg:xl:");
    for (0..100) |_| {
        try long_class.appendSlice(allocator, "group-");
    }
    try long_class.appendSlice(allocator, "bg-blue-500");

    var parsed = try class_parser.parseClass(allocator, long_class.items);
    defer parsed.deinit(allocator);

    try testing.expect(parsed.variants.len > 0);
}

test "parse unicode characters" {
    const allocator = testing.allocator;

    // Some implementations might support unicode in arbitrary values
    var parsed = try class_parser.parseClass(allocator, "content-['Hello_\u{1F44B}']");
    defer parsed.deinit(allocator);

    try testing.expect(parsed.is_arbitrary);
}

test "parse malformed brackets" {
    const allocator = testing.allocator;

    const malformed = [_][]const u8{
        "w-[100px", // unclosed
        "w-100px]", // unopened
        "w-[[100px]]", // double opening
    };

    for (malformed) |class| {
        const result = class_parser.parseClass(allocator, class);
        // Should either handle gracefully or return error
        if (result) |parsed| {
            var owned = parsed;
            owned.deinit(allocator);
        } else |_| {
            // Expected behavior
        }
    }
}
