const std = @import("std");

/// Work item for thread pool
pub const WorkItem = struct {
    func: *const fn (*WorkItem) void,
    data: ?*anyopaque = null,
};

/// OPTIMIZED Thread pool for parallel processing
/// Improvements:
/// - Work-stealing queue for better load balancing
/// - Reduced lock contention with per-thread queues
/// - Better cache locality with thread-local work
pub const ThreadPool = struct {
    allocator: std.mem.Allocator,
    threads: []std.Thread,
    work_queues: []WorkQueue, // Per-thread work queues for work stealing
    global_queue: WorkQueue, // Fallback global queue
    queue_mutex: std.Io.Mutex,
    queue_condition: std.Thread.Condition,
    shutdown: std.atomic.Value(bool),
    pending_work: std.atomic.Value(u32),

    const WorkQueue = struct {
        items: std.ArrayList(WorkItem),
        mutex: std.Io.Mutex,

        fn init(allocator: std.mem.Allocator) WorkQueue {
            return .{
                .items = std.ArrayList(WorkItem).init(allocator),
                .mutex = .init,
            };
        }

        fn deinit(self: *WorkQueue) void {
            self.items.deinit();
        }

        fn push(self: *WorkQueue, work: WorkItem) !void {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);
            try self.items.append(work);
        }

        fn pop(self: *WorkQueue) ?WorkItem {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);
            if (self.items.items.len > 0) {
                return self.items.orderedRemove(0);
            }
            return null;
        }

        fn steal(self: *WorkQueue) ?WorkItem {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);
            if (self.items.items.len > 0) {
                // Steal from the end for better cache behavior
                return self.items.pop();
            }
            return null;
        }

        fn len(self: *WorkQueue) usize {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);
            return self.items.items.len;
        }
    };

    pub fn init(allocator: std.mem.Allocator, num_threads: usize) !ThreadPool {
        const thread_count = if (num_threads == 0)
            try std.Thread.getCpuCount()
        else
            num_threads;

        var pool = ThreadPool{
            .allocator = allocator,
            .threads = try allocator.alloc(std.Thread, thread_count),
            .work_queues = try allocator.alloc(WorkQueue, thread_count),
            .global_queue = WorkQueue.init(allocator),
            .queue_mutex = .init,
            .queue_condition = .{},
            .shutdown = std.atomic.Value(bool).init(false),
            .pending_work = std.atomic.Value(u32).init(0),
        };

        // Initialize per-thread queues
        for (pool.work_queues) |*queue| {
            queue.* = WorkQueue.init(allocator);
        }

        // Start worker threads
        for (pool.threads, 0..) |*thread, i| {
            thread.* = try std.Thread.spawn(.{}, workerThread, .{ &pool, i });
        }

        return pool;
    }

    pub fn deinit(self: *ThreadPool) void {
        // Signal shutdown
        self.shutdown.store(true, .seq_cst);
        self.queue_condition.broadcast();

        // Wait for all threads to finish
        for (self.threads) |thread| {
            thread.join();
        }

        self.allocator.free(self.threads);

        for (self.work_queues) |*queue| {
            queue.deinit();
        }
        self.allocator.free(self.work_queues);

        self.global_queue.deinit();
    }

    /// Submit work to the pool
    /// OPTIMIZED: Round-robin distribution to per-thread queues
    pub fn submit(self: *ThreadPool, work: WorkItem) !void {
        if (self.shutdown.load(.seq_cst)) {
            return error.PoolShutdown;
        }

        // Increment pending work counter
        _ = self.pending_work.fetchAdd(1, .seq_cst);

        // Try to distribute work to thread queues using round-robin
        const thread_idx = self.pending_work.load(.seq_cst) % self.threads.len;

        try self.work_queues[thread_idx].push(work);
        self.queue_condition.signal();
    }

    /// Submit multiple work items in batch (more efficient)
    pub fn submitBatch(self: *ThreadPool, works: []const WorkItem) !void {
        if (self.shutdown.load(.seq_cst)) {
            return error.PoolShutdown;
        }

        // Distribute work across threads
        for (works, 0..) |work, i| {
            const thread_idx = i % self.threads.len;
            try self.work_queues[thread_idx].push(work);
            _ = self.pending_work.fetchAdd(1, .seq_cst);
        }

        self.queue_condition.broadcast(); // Wake all threads
    }

    /// Wait for all work to complete
    pub fn wait(self: *ThreadPool) void {
        while (self.pending_work.load(.seq_cst) > 0) {
            std.Thread.yield() catch {};
        }
    }

    /// Get number of worker threads
    pub fn threadCount(self: *const ThreadPool) usize {
        return self.threads.len;
    }

    /// Worker thread function with work stealing
    /// OPTIMIZED: Each thread has its own queue and can steal from others
    fn workerThread(pool: *ThreadPool, thread_id: usize) void {
        while (true) {
            // Check for shutdown
            if (pool.shutdown.load(.seq_cst)) {
                break;
            }

            // Try to get work from own queue first (best cache locality)
            var work: ?WorkItem = pool.work_queues[thread_id].pop();

            // If no work in own queue, try to steal from others
            if (work == null) {
                // Try stealing from other threads (round-robin)
                var attempts: usize = 0;
                while (attempts < pool.threads.len) : (attempts += 1) {
                    const steal_idx = (thread_id + attempts + 1) % pool.threads.len;
                    work = pool.work_queues[steal_idx].steal();
                    if (work != null) break;
                }
            }

            // If still no work, try global queue
            if (work == null) {
                work = pool.global_queue.pop();
            }

            // If still no work, wait for signal
            if (work == null) {
                pool.queue_mutex.lock();

                // Double-check before waiting
                var has_work = false;
                for (pool.work_queues) |*queue| {
                    if (queue.len() > 0) {
                        has_work = true;
                        break;
                    }
                }

                if (!has_work and !pool.shutdown.load(.seq_cst)) {
                    pool.queue_condition.wait(&pool.queue_mutex);
                }

                pool.queue_mutex.unlock();
                continue;
            }

            // Execute work
            if (work) |w| {
                w.func(@constCast(&w));
                _ = pool.pending_work.fetchSub(1, .seq_cst);
            }
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

    // Wait for all work to complete
    pool.wait();

    try std.testing.expectEqual(@as(u32, 10), ctx.counter.load(.seq_cst));
}

test "thread pool auto thread count" {
    var pool = try ThreadPool.init(std.testing.allocator, 0);
    defer pool.deinit();

    const cpu_count = try std.Thread.getCpuCount();
    try std.testing.expectEqual(cpu_count, pool.threadCount());
}

test "thread pool batch submit" {
    const TestContext = struct {
        counter: std.atomic.Value(u32),

        fn workFunc(item: *WorkItem) void {
            const ctx: *@This() = @ptrCast(@alignCast(item.data.?));
            _ = ctx.counter.fetchAdd(1, .seq_cst);
        }
    };

    var pool = try ThreadPool.init(std.testing.allocator, 4);
    defer pool.deinit();

    var ctx = TestContext{
        .counter = std.atomic.Value(u32).init(0),
    };

    // Submit batch of work
    var works: [100]WorkItem = undefined;
    for (&works) |*work| {
        work.* = .{
            .func = TestContext.workFunc,
            .data = &ctx,
        };
    }

    try pool.submitBatch(&works);
    pool.wait();

    try std.testing.expectEqual(@as(u32, 100), ctx.counter.load(.seq_cst));
}
