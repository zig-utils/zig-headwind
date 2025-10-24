const std = @import("std");

/// Fundamental error set for Headwind
pub const HeadwindError = error{
    // Config errors
    ConfigLoadFailed,
    ConfigInvalid,
    ConfigNotFound,

    // File system errors
    FileNotFound,
    DirectoryNotFound,
    PermissionDenied,
    InvalidPath,

    // Parsing errors
    InvalidClassName,
    InvalidVariant,
    InvalidArbitraryValue,
    ParserError,

    // Generation errors
    CSSGenerationFailed,
    MinificationFailed,
    SourceMapGenerationFailed,

    // Cache errors
    CacheReadFailed,
    CacheWriteFailed,
    CacheInvalidated,

    // Plugin errors
    PluginLoadFailed,
    PluginInvalid,
    PluginNotFound,

    // Memory errors
    OutOfMemory,
    AllocationFailed,
};

/// Represents a utility class name that was extracted
pub const ClassName = struct {
    /// The full class name as found in the source
    raw: []const u8,
    /// Parsed variants (e.g., ["hover", "focus", "md"])
    variants: [][]const u8,
    /// The base utility name (e.g., "bg-red-500")
    utility: []const u8,
    /// Whether this contains an arbitrary value
    is_arbitrary: bool,
    /// Source location information
    location: SourceLocation,

    pub fn deinit(self: *ClassName, allocator: std.mem.Allocator) void {
        allocator.free(self.variants);
    }
};

/// Source location for debugging and error reporting
pub const SourceLocation = struct {
    file: []const u8,
    line: u32,
    column: u32,
};

/// Represents a CSS rule
pub const CSSRule = struct {
    /// CSS selector
    selector: []const u8,
    /// CSS declarations (property: value pairs)
    declarations: std.StringHashMap([]const u8),
    /// Layer (@layer utilities, components, etc.)
    layer: ?Layer = null,
    /// Media query wrapper
    media: ?[]const u8 = null,
    /// Container query wrapper
    container: ?[]const u8 = null,
    /// Pseudo-classes/elements
    pseudo: ?[]const u8 = null,

    pub fn deinit(self: *CSSRule, allocator: std.mem.Allocator) void {
        var iter = self.declarations.iterator();
        while (iter.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            allocator.free(entry.value_ptr.*);
        }
        self.declarations.deinit();
    }
};

/// CSS cascade layers
pub const Layer = enum {
    base,
    components,
    utilities,
    custom,

    pub fn toString(self: Layer) []const u8 {
        return switch (self) {
            .base => "base",
            .components => "components",
            .utilities => "utilities",
            .custom => "custom",
        };
    }
};

/// Build mode for output optimization
pub const BuildMode = enum {
    development,
    production,

    pub fn shouldMinify(self: BuildMode) bool {
        return self == .production;
    }
};

/// Represents extracted content from a file
pub const FileContent = struct {
    /// File path
    path: []const u8,
    /// Extracted class names
    classes: []ClassName,
    /// File hash for cache invalidation
    hash: u64,
    /// Last modified timestamp
    modified_at: i64,

    pub fn deinit(self: *FileContent, allocator: std.mem.Allocator) void {
        for (self.classes) |*class| {
            class.deinit(allocator);
        }
        allocator.free(self.classes);
    }
};

/// Cache entry for processed files
pub const CacheEntry = struct {
    /// File hash
    hash: u64,
    /// Extracted classes
    classes: []ClassName,
    /// Timestamp when cached
    cached_at: i64,
    /// Generated CSS output
    css: ?[]const u8 = null,

    pub fn deinit(self: *CacheEntry, allocator: std.mem.Allocator) void {
        for (self.classes) |*class| {
            class.deinit(allocator);
        }
        allocator.free(self.classes);
        if (self.css) |css| {
            allocator.free(css);
        }
    }
};

/// Scan result containing all extracted classes
pub const ScanResult = struct {
    /// All extracted file contents
    files: []FileContent,
    /// Total class count
    total_classes: usize,
    /// Unique class count
    unique_classes: usize,
    /// Scan duration in nanoseconds
    duration_ns: i64,

    pub fn deinit(self: *ScanResult, allocator: std.mem.Allocator) void {
        for (self.files) |*file| {
            file.deinit(allocator);
        }
        allocator.free(self.files);
    }
};

/// Plugin interface
pub const Plugin = struct {
    name: []const u8,
    version: []const u8,

    /// Initialize the plugin
    init: *const fn (allocator: std.mem.Allocator) anyerror!void,

    /// Add custom utilities
    addUtilities: ?*const fn (allocator: std.mem.Allocator) anyerror![]CSSRule = null,

    /// Add custom variants
    addVariants: ?*const fn (allocator: std.mem.Allocator) anyerror![]Variant = null,

    /// Cleanup
    deinit: *const fn (allocator: std.mem.Allocator) void,
};

/// Represents a variant modifier
pub const Variant = struct {
    name: []const u8,
    transform: *const fn (selector: []const u8, allocator: std.mem.Allocator) anyerror![]const u8,
};

/// Memory pool for efficient allocation
pub const MemoryPool = struct {
    arena: std.heap.ArenaAllocator,

    pub fn init(backing_allocator: std.mem.Allocator) MemoryPool {
        return .{
            .arena = std.heap.ArenaAllocator.init(backing_allocator),
        };
    }

    pub fn allocator(self: *MemoryPool) std.mem.Allocator {
        return self.arena.allocator();
    }

    pub fn deinit(self: *MemoryPool) void {
        self.arena.deinit();
    }

    pub fn reset(self: *MemoryPool) void {
        _ = self.arena.reset(.retain_capacity);
    }
};

/// Statistics for performance monitoring
pub const Stats = struct {
    files_scanned: usize = 0,
    classes_extracted: usize = 0,
    css_rules_generated: usize = 0,
    cache_hits: usize = 0,
    cache_misses: usize = 0,
    total_duration_ns: i64 = 0,

    pub fn report(self: Stats) void {
        std.debug.print("=== Headwind Stats ===\n", .{});
        std.debug.print("Files scanned: {d}\n", .{self.files_scanned});
        std.debug.print("Classes extracted: {d}\n", .{self.classes_extracted});
        std.debug.print("CSS rules generated: {d}\n", .{self.css_rules_generated});
        std.debug.print("Cache hits: {d}\n", .{self.cache_hits});
        std.debug.print("Cache misses: {d}\n", .{self.cache_misses});
        std.debug.print("Duration: {d}ms\n", .{@divTrunc(self.total_duration_ns, 1_000_000)});
    }
};
