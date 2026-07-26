const std = @import("std");
const builtin = @import("builtin");

/// File watcher for monitoring file changes
pub const FileWatcher = struct {
    allocator: std.mem.Allocator,
    paths: std.ArrayList([]const u8),
    callback: *const fn (path: []const u8) void,
    running: std.atomic.Value(bool),

    pub fn init(allocator: std.mem.Allocator, callback: *const fn (path: []const u8) void) !FileWatcher {
        return .{
            .allocator = allocator,
            .paths = .empty,
            .callback = callback,
            .running = std.atomic.Value(bool).init(false),
        };
    }

    pub fn deinit(self: *FileWatcher) void {
        for (self.paths.items) |path| {
            self.allocator.free(path);
        }
        self.paths.deinit(self.allocator);
    }

    pub fn addPath(self: *FileWatcher, path: []const u8) !void {
        const owned_path = try self.allocator.dupe(u8, path);
        try self.paths.append(self.allocator, owned_path);
    }

    pub fn start(self: *FileWatcher) !void {
        self.running.store(true, .seq_cst);

        // Platform-specific implementation
        switch (builtin.os.tag) {
            .macos => try self.startMacOS(),
            .linux => try self.startLinux(),
            .windows => try self.startWindows(),
            else => return error.UnsupportedPlatform,
        }
    }

    pub fn stop(self: *FileWatcher) void {
        self.running.store(false, .seq_cst);
    }

    fn startMacOS(self: *FileWatcher) !void {
        // FSEvents implementation would go here
        // For now, use polling as a fallback
        try self.pollForChanges();
    }

    fn startLinux(self: *FileWatcher) !void {
        // inotify implementation would go here
        // For now, use polling as a fallback
        try self.pollForChanges();
    }

    fn startWindows(self: *FileWatcher) !void {
        // ReadDirectoryChangesW implementation would go here
        // For now, use polling as a fallback
        try self.pollForChanges();
    }

    /// Simple polling implementation (fallback)
    fn pollForChanges(self: *FileWatcher) !void {
        var file_times = std.StringHashMap(i96).init(self.allocator);
        defer file_times.deinit();

        // Initialize file modification times
        for (self.paths.items) |path| {
            const stat = std.fs.cwd().statFile(path) catch continue;
            try file_times.put(path, stat.mtime.nanoseconds);
        }

        while (self.running.load(.seq_cst)) {
            std.posix.nanosleep(0, 500 * std.time.ns_per_ms); // Poll every 500ms

            for (self.paths.items) |path| {
                const stat = std.fs.cwd().statFile(path) catch continue;
                const old_time = file_times.get(path) orelse continue;

                if (stat.mtime.nanoseconds != old_time) {
                    try file_times.put(path, stat.mtime.nanoseconds);
                    self.callback(path);
                }
            }
        }
    }
};

/// Debouncer to prevent rapid successive rebuilds
pub const Debouncer = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    delay_ms: u64,
    /// Monotonic nanoseconds of the last accepted event; 0 until the first.
    /// 0.17 removed std.time.Timer, so elapsed time is the difference between
    /// two Io timestamps rather than a timer's running count.
    last_event_ns: i96,
    mutex: std.Thread.Mutex,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, delay_ms: u64) Debouncer {
        return .{
            .allocator = allocator,
            .io = io,
            .delay_ms = delay_ms,
            .last_event_ns = 0,
            .mutex = std.Thread.Mutex{},
        };
    }

    pub fn trigger(self: *Debouncer) bool {
        self.mutex.lock();
        defer self.mutex.unlock();

        const now_ns = std.Io.Timestamp.now(self.io, .awake).toNanoseconds();

        // The very first event always fires: there is no previous timestamp to
        // debounce against, and `0` would otherwise read as "long ago" only by
        // accident of the epoch.
        if (self.last_event_ns == 0) {
            self.last_event_ns = now_ns;
            return true;
        }

        const elapsed_ms = @divTrunc(now_ns - self.last_event_ns, std.time.ns_per_ms);
        if (elapsed_ms >= self.delay_ms) {
            self.last_event_ns = now_ns;
            return true;
        }

        return false;
    }

    pub fn reset(self: *Debouncer) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.last_event = 0;
    }
};

test "FileWatcher init/deinit" {
    const allocator = std.testing.allocator;

    const callback = struct {
        fn onChange(path: []const u8) void {
            _ = path;
        }
    }.onChange;

    var watcher = FileWatcher.init(allocator, callback);
    defer watcher.deinit();

    try watcher.addPath("test.txt");
}

test "Debouncer" {
    const allocator = std.testing.allocator;
    var debouncer = Debouncer.init(allocator, 100);

    // First trigger should succeed
    try std.testing.expect(debouncer.trigger());

    // Immediate second trigger should fail
    try std.testing.expect(!debouncer.trigger());

    // Wait for delay
    std.Thread.sleep(150 * std.time.ns_per_ms);

    // Should succeed after delay
    try std.testing.expect(debouncer.trigger());
}
