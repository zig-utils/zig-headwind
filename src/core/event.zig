const std = @import("std");

/// Event types
pub const EventType = enum {
    file_created,
    file_modified,
    file_deleted,
    directory_created,
    directory_deleted,
    config_changed,
    build_started,
    build_completed,
    build_failed,
};

/// Event data
pub const Event = struct {
    type: EventType,
    path: ?[]const u8 = null,
    data: ?*anyopaque = null,
    timestamp: i64,

    pub fn init(event_type: EventType) Event {
        return .{
            .type = event_type,
            .timestamp = std.time.timestamp(),
        };
    }

    pub fn withPath(event_type: EventType, path: []const u8) Event {
        return .{
            .type = event_type,
            .path = path,
            .timestamp = std.time.timestamp(),
        };
    }
};

/// Event handler function type
pub const EventHandler = *const fn (Event) void;

/// Event subscriber
const Subscriber = struct {
    id: u64,
    handler: EventHandler,
    event_type: ?EventType, // null means subscribe to all events
};

/// Event bus for pub/sub pattern
pub const EventBus = struct {
    allocator: std.mem.Allocator,
    subscribers: std.ArrayList(Subscriber),
    next_id: u64,
    mutex: std.Thread.Mutex,

    pub fn init(allocator: std.mem.Allocator) EventBus {
        return .{
            .allocator = allocator,
            .subscribers = std.ArrayList(Subscriber).init(allocator),
            .next_id = 1,
            .mutex = .{},
        };
    }

    pub fn deinit(self: *EventBus) void {
        self.subscribers.deinit();
    }

    /// Subscribe to specific event type
    pub fn subscribe(self: *EventBus, event_type: EventType, handler: EventHandler) !u64 {
        self.mutex.lock();
        defer self.mutex.unlock();

        const id = self.next_id;
        self.next_id += 1;

        try self.subscribers.append(.{
            .id = id,
            .handler = handler,
            .event_type = event_type,
        });

        return id;
    }

    /// Subscribe to all events
    pub fn subscribeAll(self: *EventBus, handler: EventHandler) !u64 {
        self.mutex.lock();
        defer self.mutex.unlock();

        const id = self.next_id;
        self.next_id += 1;

        try self.subscribers.append(.{
            .id = id,
            .handler = handler,
            .event_type = null,
        });

        return id;
    }

    /// Unsubscribe by ID
    pub fn unsubscribe(self: *EventBus, id: u64) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        var i: usize = 0;
        while (i < self.subscribers.items.len) {
            if (self.subscribers.items[i].id == id) {
                _ = self.subscribers.orderedRemove(i);
                return;
            }
            i += 1;
        }
    }

    /// Publish an event
    pub fn publish(self: *EventBus, event: Event) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        for (self.subscribers.items) |subscriber| {
            // Call handler if subscribed to this event type or all events
            if (subscriber.event_type == null or subscriber.event_type.? == event.type) {
                subscriber.handler(event);
            }
        }
    }

    /// Get number of subscribers
    pub fn subscriberCount(self: *const EventBus) usize {
        return self.subscribers.items.len;
    }
};

/// Global event bus
var global_event_bus: ?EventBus = null;
var global_event_bus_mutex: std.Thread.Mutex = .{};

/// Initialize global event bus
pub fn initGlobal(allocator: std.mem.Allocator) !void {
    global_event_bus_mutex.lock();
    defer global_event_bus_mutex.unlock();

    if (global_event_bus == null) {
        global_event_bus = EventBus.init(allocator);
    }
}

/// Deinitialize global event bus
pub fn deinitGlobal() void {
    global_event_bus_mutex.lock();
    defer global_event_bus_mutex.unlock();

    if (global_event_bus) |*bus| {
        bus.deinit();
        global_event_bus = null;
    }
}

/// Get global event bus
pub fn getGlobal() *EventBus {
    global_event_bus_mutex.lock();
    defer global_event_bus_mutex.unlock();

    return &global_event_bus.?;
}

/// Convenience functions for global event bus
pub fn subscribe(event_type: EventType, handler: EventHandler) !u64 {
    return getGlobal().subscribe(event_type, handler);
}

pub fn subscribeAll(handler: EventHandler) !u64 {
    return getGlobal().subscribeAll(handler);
}

pub fn unsubscribe(id: u64) void {
    getGlobal().unsubscribe(id);
}

pub fn publish(event: Event) void {
    getGlobal().publish(event);
}

test "event bus basic operations" {
    var bus = EventBus.init(std.testing.allocator);
    defer bus.deinit();

    const TestContext = struct {
        var call_count: u32 = 0;

        fn handler(event: Event) void {
            _ = event;
            call_count += 1;
        }
    };

    TestContext.call_count = 0;

    const id = try bus.subscribe(.file_modified, TestContext.handler);
    try std.testing.expectEqual(@as(usize, 1), bus.subscriberCount());

    bus.publish(Event.init(.file_modified));
    try std.testing.expectEqual(@as(u32, 1), TestContext.call_count);

    bus.unsubscribe(id);
    try std.testing.expectEqual(@as(usize, 0), bus.subscriberCount());
}

test "event bus multiple subscribers" {
    var bus = EventBus.init(std.testing.allocator);
    defer bus.deinit();

    const TestContext = struct {
        var call_count1: u32 = 0;
        var call_count2: u32 = 0;

        fn handler1(event: Event) void {
            _ = event;
            call_count1 += 1;
        }

        fn handler2(event: Event) void {
            _ = event;
            call_count2 += 1;
        }
    };

    TestContext.call_count1 = 0;
    TestContext.call_count2 = 0;

    _ = try bus.subscribe(.file_modified, TestContext.handler1);
    _ = try bus.subscribe(.file_modified, TestContext.handler2);

    bus.publish(Event.init(.file_modified));

    try std.testing.expectEqual(@as(u32, 1), TestContext.call_count1);
    try std.testing.expectEqual(@as(u32, 1), TestContext.call_count2);
}

test "event bus subscribe all" {
    var bus = EventBus.init(std.testing.allocator);
    defer bus.deinit();

    const TestContext = struct {
        var call_count: u32 = 0;

        fn handler(event: Event) void {
            _ = event;
            call_count += 1;
        }
    };

    TestContext.call_count = 0;

    _ = try bus.subscribeAll(TestContext.handler);

    bus.publish(Event.init(.file_modified));
    bus.publish(Event.init(.file_created));
    bus.publish(Event.init(.build_completed));

    try std.testing.expectEqual(@as(u32, 3), TestContext.call_count);
}
