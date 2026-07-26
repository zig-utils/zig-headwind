const std = @import("std");
const testing = std.testing;
const crosswind = @import("crosswind");

const class_parser = crosswind.class_parser;

// ============================================================================
// Arbitrary Value Parsing Tests
// ============================================================================

test "parse arbitrary color values - hex" {
    const allocator = testing.allocator;

    const hex_colors = [_][]const u8{
        "bg-[#ff0000]",
        "bg-[#f00]",
        "bg-[#rrggbb]",
        "bg-[#rrggbbaa]",
        "text-[#123456]",
    };

    for (hex_colors) |class| {
        var parsed = try class_parser.parseClass(allocator, class);
        defer parsed.deinit(allocator);

        try testing.expect(parsed.is_arbitrary);
        try testing.expect(parsed.arbitrary_value != null);
    }
}

test "parse arbitrary color values - rgb/rgba" {
    const allocator = testing.allocator;

    const rgb_colors = [_][]const u8{
        "bg-[rgb(255,0,0)]",
        "bg-[rgba(255,0,0,0.5)]",
        "text-[rgb(100,200,50)]",
    };

    for (rgb_colors) |class| {
        var parsed = try class_parser.parseClass(allocator, class);
        defer parsed.deinit(allocator);

        try testing.expect(parsed.is_arbitrary);
        try testing.expect(parsed.arbitrary_value != null);
    }
}

test "parse arbitrary length values" {
    const allocator = testing.allocator;

    const lengths = [_][]const u8{
        "w-[100px]",
        "w-[10rem]",
        "w-[50%]",
        "w-[10vh]",
        "w-[calc(100%-20px)]",
        "w-[min(100%,500px)]",
        "w-[max(200px,50%)]",
        "w-[clamp(200px,50%,500px)]",
    };

    for (lengths) |class| {
        var parsed = try class_parser.parseClass(allocator, class);
        defer parsed.deinit(allocator);

        try testing.expect(parsed.is_arbitrary);
        try testing.expect(parsed.arbitrary_value != null);
    }
}

test "parse arbitrary values with spaces (underscores)" {
    const allocator = testing.allocator;

    const with_spaces = [_][]const u8{
        "bg-[rgb(255,_0,_0)]",
        "grid-cols-[1fr_2fr_1fr]",
        "content-['hello_world']",
    };

    for (with_spaces) |class| {
        var parsed = try class_parser.parseClass(allocator, class);
        defer parsed.deinit(allocator);

        try testing.expect(parsed.is_arbitrary);
        try testing.expect(parsed.arbitrary_value != null);
    }
}

test "parse arbitrary values with nested brackets" {
    const allocator = testing.allocator;

    const nested = [_][]const u8{
        "content-['hello_[world]']",
        "bg-[url('/path/to/image.png')]",
    };

    for (nested) |class| {
        var parsed = try class_parser.parseClass(allocator, class);
        defer parsed.deinit(allocator);

        try testing.expect(parsed.is_arbitrary);
        try testing.expect(parsed.arbitrary_value != null);
    }
}

test "parse arbitrary selectors" {
    const allocator = testing.allocator;

    var parsed = try class_parser.parseClass(allocator, "[&:nth-child(3)]:bg-red");
    defer parsed.deinit(allocator);

    try testing.expect(parsed.variants.len > 0);
}

// ============================================================================
// Edge Cases
// ============================================================================

test "parse empty arbitrary value" {
    const allocator = testing.allocator;

    var parsed = try class_parser.parseClass(allocator, "w-[]");
    defer parsed.deinit(allocator);

    try testing.expect(parsed.is_arbitrary);
}

test "parse unclosed bracket" {
    const allocator = testing.allocator;

    // This should handle gracefully
    const result = class_parser.parseClass(allocator, "w-[100px");
    if (result) |parsed| {
        parsed.deinit(allocator);
    } else |_| {
        // Expected to fail or handle gracefully
    }
}

test "parse very long arbitrary value" {
    const allocator = testing.allocator;

    const long_value = "w-[" ++ "x" * *500 ++ "]";
    const class_str = try std.fmt.allocPrint(allocator, "{s}", .{long_value});
    defer allocator.free(class_str);

    var parsed = try class_parser.parseClass(allocator, class_str);
    defer parsed.deinit(allocator);

    try testing.expect(parsed.is_arbitrary);
}
