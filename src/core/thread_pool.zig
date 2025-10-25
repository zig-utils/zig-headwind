const std = @import("std");

/// Work item for thread pool
pub const WorkItem = struct {
    func: *const fn (*WorkItem) void,
    data: ?*anyopaque = null,
};

/// Thread pool for parallel processing
pub const ThreadPool = struct {
    allocator: std.mem.Allocator,
    threads: []std.Thread,
    work_queue: std.ArrayList(WorkItem),
    queue_mutex: std.Thread.Mutex,
    queue_condition: std.Thread.Condition,
    shutdown: bool,

    pub fn init(allocator: std.mem.Allocator, num_threads: usize) !ThreadPool {
        const thread_count = if (num_threads == 0)
            try std.Thread.getCpuCount()
        else
            num_threads;

        var pool = ThreadPool{
            .allocator = allocator,
            .threads = try allocator.alloc(std.Thread, thread_count),
            .work_queue = std.ArrayList(WorkItem){},
            .queue_mutex = .{},
            .queue_condition = .{},
            .shutdown = false,
        };

        // Start worker threads
        for (pool.threads, 0..) |*thread, i| {
            thread.* = try std.Thread.spawn(.{}, workerThread, .{&pool});
            _ = i;
        }

        return pool;
    }

    pub fn deinit(self: *ThreadPool) void {
        // Signal shutdown
        self.queue_mutex.lock();
        self.shutdown = true;
        self.queue_condition.broadcast();
        self.queue_mutex.unlock();

        // Wait for all threads to finish
        for (self.threads) |thread| {
            thread.join();
        }

        self.allocator.free(self.threads);
        self.work_queue.deinit(self.allocator);
    }

    /// Submit work to the pool
    pub fn submit(self: *ThreadPool, work: WorkItem) !void {
        self.queue_mutex.lock();
        defer self.queue_mutex.unlock();

        if (self.shutdown) {
            return error.PoolShutdown;
        }

        try self.work_queue.append(self.allocator, work);
        self.queue_condition.signal();
    }

    /// Get number of worker threads
    pub fn threadCount(self: *const ThreadPool) usize {
        return self.threads.len;
    }

    /// Worker thread function
    fn workerThread(pool: *ThreadPool) void {
        while (true) {
            pool.queue_mutex.lock();

            // Wait for work or shutdown signal
            while (pool.work_queue.items.len == 0 and !pool.shutdown) {
                pool.queue_condition.wait(&pool.queue_mutex);
            }

            // Check for shutdown
            if (pool.shutdown and pool.work_queue.items.len == 0) {
                pool.queue_mutex.unlock();
                break;
            }

            // Get work item
            const work = pool.work_queue.orderedRemove(0);
            pool.queue_mutex.unlock();

            // Execute work
            work.func(@constCast(&work));
        }
    }
};

test "thread pool basic operations" {
    const TestContext = struct {
        counter: std.atomic.Value(u32),

        fn workFunc(item: *WorkItem) void {
            const ctx: *@This() = @ptrCast(@alignCast(item.data.?));
            _ = ctx.counter.fetchAdd(1, .seq_cst);
        }
    };

    var pool = try ThreadPool.init(std.testing.allocator, 2);
    defer pool.deinit();

    var ctx = TestContext{
        .counter = std.atomic.Value(u32).init(0),
    };

    // Submit multiple work items
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        try pool.submit(.{
            .func = TestContext.workFunc,
            .data = &ctx,
        });
    }

    // Wait a bit for work to complete
    std.Thread.sleep(100 * std.time.ns_per_ms);

    try std.testing.expectEqual(@as(u32, 10), ctx.counter.load(.seq_cst));
}

test "thread pool auto thread count" {
    var pool = try ThreadPool.init(std.testing.allocator, 0);
    defer pool.deinit();

    const cpu_count = try std.Thread.getCpuCount();
    try std.testing.expectEqual(cpu_count, pool.threadCount());
}
