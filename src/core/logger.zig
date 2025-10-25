const std = @import("std");

/// Log levels
pub const LogLevel = enum(u8) {
    debug = 0,
    info = 1,
    warn = 2,
    err = 3,
    none = 4,

    pub fn toString(self: LogLevel) []const u8 {
        return switch (self) {
            .debug => "DEBUG",
            .info => "INFO",
            .warn => "WARN",
            .err => "ERROR",
            .none => "NONE",
        };
    }

    pub fn color(self: LogLevel) []const u8 {
        return switch (self) {
            .debug => "\x1b[36m", // Cyan
            .info => "\x1b[32m", // Green
            .warn => "\x1b[33m", // Yellow
            .err => "\x1b[31m", // Red
            .none => "\x1b[0m", // Reset
        };
    }
};

/// Logger configuration
pub const LoggerConfig = struct {
    level: LogLevel = .info,
    use_color: bool = true,
    include_timestamp: bool = false,
    include_level: bool = true,
};

/// Global logger instance
pub const Logger = struct {
    config: LoggerConfig,
    mutex: std.Thread.Mutex,

    pub fn init(config: LoggerConfig) Logger {
        return .{
            .config = config,
            .mutex = .{},
        };
    }

    /// Log a debug message
    pub fn debug(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.log(.debug, fmt, args);
    }

    /// Log an info message
    pub fn info(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.log(.info, fmt, args);
    }

    /// Log a warning message
    pub fn warn(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.log(.warn, fmt, args);
    }

    /// Log an error message
    pub fn err(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.log(.err, fmt, args);
    }

    /// Core logging function
    pub fn log(self: *Logger, level: LogLevel, comptime fmt: []const u8, args: anytype) void {
        // Check if this log level should be printed
        if (@intFromEnum(level) < @intFromEnum(self.config.level)) {
            return;
        }

        self.mutex.lock();
        defer self.mutex.unlock();

        // Use std.debug.print which handles stderr correctly
        if (self.config.use_color) {
            if (self.config.include_level) {
                std.debug.print("{s}[{s}] " ++ fmt ++ "\x1b[0m\n", .{level.color(), level.toString()} ++ args);
            } else {
                std.debug.print("{s}" ++ fmt ++ "\x1b[0m\n", .{level.color()} ++ args);
            }
        } else {
            if (self.config.include_level) {
                std.debug.print("[{s}] " ++ fmt ++ "\n", .{level.toString()} ++ args);
            } else {
                std.debug.print(fmt ++ "\n", args);
            }
        }
    }

    /// Set log level
    pub fn setLevel(self: *Logger, level: LogLevel) void {
        self.config.level = level;
    }

    /// Enable/disable color output
    pub fn setColor(self: *Logger, enabled: bool) void {
        self.config.use_color = enabled;
    }
};

/// Global logger instance
var global_logger: ?Logger = null;
var global_logger_mutex: std.Thread.Mutex = .{};

/// Initialize global logger
pub fn initGlobal(config: LoggerConfig) void {
    global_logger_mutex.lock();
    defer global_logger_mutex.unlock();
    global_logger = Logger.init(config);
}

/// Get global logger
pub fn getGlobal() *Logger {
    global_logger_mutex.lock();
    defer global_logger_mutex.unlock();

    if (global_logger) |*logger| {
        return logger;
    }

    // Initialize with default config if not set
    global_logger = Logger.init(.{});
    return &global_logger.?;
}

/// Convenience functions for global logger
pub fn debug(comptime fmt: []const u8, args: anytype) void {
    getGlobal().debug(fmt, args);
}

pub fn info(comptime fmt: []const u8, args: anytype) void {
    getGlobal().info(fmt, args);
}

pub fn warn(comptime fmt: []const u8, args: anytype) void {
    getGlobal().warn(fmt, args);
}

pub fn err(comptime fmt: []const u8, args: anytype) void {
    getGlobal().err(fmt, args);
}

pub fn setLevel(level: LogLevel) void {
    getGlobal().setLevel(level);
}

test "logger basic operations" {
    var logger = Logger.init(.{ .level = .debug });

    logger.debug("Debug message: {s}", .{"test"});
    logger.info("Info message: {d}", .{42});
    logger.warn("Warning message", .{});
    logger.err("Error message", .{});
}

test "logger level filtering" {
    var logger = Logger.init(.{ .level = .warn });

    // These should not output (but we can't easily test that)
    logger.debug("Should not appear", .{});
    logger.info("Should not appear", .{});

    // These should output
    logger.warn("Should appear", .{});
    logger.err("Should appear", .{});
}
