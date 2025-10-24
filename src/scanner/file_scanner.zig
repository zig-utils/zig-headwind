const std = @import("std");
const types = @import("../core/types.zig");
const string_utils = @import("../utils/string.zig");

/// File scanner for discovering source files
pub const FileScanner = struct {
    allocator: std.mem.Allocator,
    include_patterns: []const []const u8,
    exclude_patterns: []const []const u8,
    base_path: []const u8,

    pub fn init(
        allocator: std.mem.Allocator,
        base_path: []const u8,
        include_patterns: []const []const u8,
        exclude_patterns: []const []const u8,
    ) FileScanner {
        return .{
            .allocator = allocator,
            .base_path = base_path,
            .include_patterns = include_patterns,
            .exclude_patterns = exclude_patterns,
        };
    }

    /// Scan all files matching include patterns
    pub fn scan(self: *FileScanner) ![][]const u8 {
        var files: std.ArrayList([]const u8) = .{};
        errdefer {
            for (files.items) |file| {
                self.allocator.free(file);
            }
            files.deinit(self.allocator);
        }

        // Open base directory
        var dir = try std.fs.cwd().openDir(self.base_path, .{ .iterate = true });
        defer dir.close();

        // Scan recursively
        try self.scanDir(dir, "", &files);

        return files.toOwnedSlice(self.allocator);
    }

    fn scanDir(
        self: *FileScanner,
        dir: std.fs.Dir,
        rel_path: []const u8,
        files: *std.ArrayList([]const u8),
    ) !void {
        var iter = dir.iterate();

        while (try iter.next()) |entry| {
            const full_rel_path = if (rel_path.len > 0)
                try std.fs.path.join(self.allocator, &.{ rel_path, entry.name })
            else
                try self.allocator.dupe(u8, entry.name);
            defer self.allocator.free(full_rel_path);

            // Check if excluded
            if (self.isExcluded(full_rel_path)) {
                continue;
            }

            switch (entry.kind) {
                .directory => {
                    // Recursively scan subdirectory
                    var subdir = try dir.openDir(entry.name, .{ .iterate = true });
                    defer subdir.close();
                    try self.scanDir(subdir, full_rel_path, files);
                },
                .file => {
                    // Check if file matches include patterns
                    if (self.matchesInclude(entry.name)) {
                        const file_path = try std.fs.path.join(
                            self.allocator,
                            &.{ self.base_path, full_rel_path },
                        );
                        try files.append(self.allocator, file_path);
                    }
                },
                else => {},
            }
        }
    }

    fn matchesInclude(self: *FileScanner, filename: []const u8) bool {
        for (self.include_patterns) |pattern| {
            if (self.matchesPattern(filename, pattern)) {
                return true;
            }
        }
        return false;
    }

    fn isExcluded(self: *FileScanner, path: []const u8) bool {
        for (self.exclude_patterns) |pattern| {
            if (self.matchesPattern(path, pattern)) {
                return true;
            }
        }
        return false;
    }

    /// Simple glob pattern matching (supports * wildcard)
    fn matchesPattern(self: *FileScanner, text: []const u8, pattern: []const u8) bool {
        _ = self;
        return matchGlob(text, pattern);
    }
};

/// Simple glob pattern matching
pub fn matchGlob(text: []const u8, pattern: []const u8) bool {
    var text_idx: usize = 0;
    var pattern_idx: usize = 0;

    while (pattern_idx < pattern.len and text_idx < text.len) {
        if (pattern[pattern_idx] == '*') {
            // Handle wildcard
            if (pattern_idx + 1 >= pattern.len) {
                // * at end matches everything
                return true;
            }

            // Try to match the rest after *
            const rest_pattern = pattern[pattern_idx + 1 ..];
            while (text_idx < text.len) {
                if (matchGlob(text[text_idx..], rest_pattern)) {
                    return true;
                }
                text_idx += 1;
            }
            return false;
        } else if (pattern[pattern_idx] == '?') {
            // ? matches any single character
            text_idx += 1;
            pattern_idx += 1;
        } else if (pattern[pattern_idx] == text[text_idx]) {
            // Exact match
            text_idx += 1;
            pattern_idx += 1;
        } else {
            return false;
        }
    }

    // Handle remaining wildcards at end of pattern
    while (pattern_idx < pattern.len and pattern[pattern_idx] == '*') {
        pattern_idx += 1;
    }

    return text_idx == text.len and pattern_idx == pattern.len;
}

/// Get file extension
pub fn getExtension(filename: []const u8) ?[]const u8 {
    var i: usize = filename.len;
    while (i > 0) {
        i -= 1;
        if (filename[i] == '.') {
            return filename[i..];
        }
        if (filename[i] == '/' or filename[i] == '\\') {
            return null;
        }
    }
    return null;
}

/// Check if file has one of the given extensions
pub fn hasExtension(filename: []const u8, extensions: []const []const u8) bool {
    const ext = getExtension(filename) orelse return false;

    for (extensions) |target_ext| {
        if (std.mem.eql(u8, ext, target_ext)) {
            return true;
        }
    }
    return false;
}

test "matchGlob simple" {
    try std.testing.expect(matchGlob("test.js", "*.js"));
    try std.testing.expect(matchGlob("test.jsx", "*.jsx"));
    try std.testing.expect(!matchGlob("test.js", "*.jsx"));
}

test "matchGlob wildcards" {
    try std.testing.expect(matchGlob("src/components/Button.tsx", "src/**/*.tsx"));
    try std.testing.expect(matchGlob("node_modules/foo", "node_modules/*"));
    try std.testing.expect(!matchGlob("src/test.js", "*.tsx"));
}

test "getExtension" {
    try std.testing.expectEqualStrings(".js", getExtension("test.js").?);
    try std.testing.expectEqualStrings(".tsx", getExtension("Component.tsx").?);
    try std.testing.expect(getExtension("noext") == null);
}

test "hasExtension" {
    const extensions = &[_][]const u8{ ".js", ".jsx", ".ts", ".tsx" };
    try std.testing.expect(hasExtension("test.js", extensions));
    try std.testing.expect(hasExtension("test.tsx", extensions));
    try std.testing.expect(!hasExtension("test.css", extensions));
}
