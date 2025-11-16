const std = @import("std");

pub const TimerState = enum { stopped, running, paused, finished };
pub const TimerType = enum { countdown, continuous };

// Time values in nanoseconds
pub const Timer = struct {
    current_time: i64 = 0,
    duration: i64 = 0,
    limit: i64 = 0,
    paused_time: i64 = 0,
    start_time: i64 = 0,
    state: TimerState = .stopped,
    timer_type: TimerType,

    pub fn init(timer_type: TimerType, duration: i64, limit: i64) Timer {
        return Timer{
            .duration = duration,
            .limit = limit,
            .timer_type = timer_type,
        };
    }
    pub fn deinit(self: *Timer) void {
        _ = self;
    }

    // METHODS ------------------------------------------------------------------------
    pub fn getCurrentTime(self: *Timer) i64 {
        return self.current_time;
    }

    pub fn getElapsedTime(self: *Timer) i64 {
        switch (self.timer_type) {
            .continuous => return self.current_time,
            .countdown => return self.duration - self.current_time,
        }
    }

    pub fn getProgress(self: *Timer) f32 {
        switch (self.timer_type) {
            .continuous => {
                if (self.limit == 0) return 0;
                return @as(f32, @floatFromInt(self.current_time)) / @as(f32, @floatFromInt(self.limit));
            },
            .countdown => {
                if (self.duration == 0) return 0;
                return 1.0 - (@as(f32, @floatFromInt(self.current_time)) / @as(f32, @floatFromInt(self.duration)));
            },
        }
    }

    pub fn getRemainingTime(self: *Timer) i64 {
        if (self.timer_type != .countdown) return 0;
        return if (self.current_time > 0) self.current_time else 0;
    }

    pub fn isFinished(self: *Timer) bool {
        return self.state == .finished;
    }

    pub fn isPaused(self: *Timer) bool {
        return self.state == .paused;
    }

    pub fn isRunning(self: *Timer) bool {
        return self.state == .running;
    }

    pub fn pause(self: *Timer) void {
        if (self.state != .running) return;
        self.state = .paused;
        self.paused_time = @intCast(std.time.nanoTimestamp());
    }

    pub fn reset(self: *Timer) void {
        self.start_time = 0;
        self.paused_time = 0;
        self.state = .stopped;

        switch (self.timer_type) {
            .continuous => self.current_time = 0,
            .countdown => self.current_time = self.duration,
        }
    }

    pub fn setDuration(self: *Timer, duration_ns: i64) void {
        self.duration = duration_ns;
        if (self.timer_type == .countdown) self.current_time = duration_ns;
    }

    pub fn setLimit(self: *Timer, limit_ns: i64) void {
        self.limit = limit_ns;
    }

    pub fn start(self: *Timer) void {
        if (self.state == .finished) self.reset();
        self.state = .running;
        if (self.timer_type == .continuous and self.current_time > 0) {
            self.start_time = @as(i64, @intCast(std.time.nanoTimestamp())) - @as(i64, @intCast(self.current_time));
        } else {
            self.start_time = @intCast(std.time.nanoTimestamp());
        }
        if (self.timer_type == .countdown and self.current_time == 0) self.current_time = self.duration;
    }

    pub fn stop(self: *Timer) void {
        self.state = .stopped;
    }

    pub fn unpause(self: *Timer) void {
        if (self.state != .paused) return;
        const paused_duration = @as(i64, @intCast(std.time.nanoTimestamp() - self.paused_time));
        self.state = .running;
        self.start_time += paused_duration;
    }

    pub fn update(self: *Timer) void {
        if (self.state != .running) return;
        const now = std.time.nanoTimestamp();
        const total_elapsed = now - self.start_time;
        switch (self.timer_type) {
            .continuous => {
                self.current_time = @as(i64, @intCast(total_elapsed));
                if (self.limit > 0 and self.current_time >= self.limit) {
                    self.state = .finished;
                    self.current_time = self.limit;
                }
            },
            .countdown => {
                const elapsed = @as(i64, @intCast(total_elapsed));
                if (elapsed >= self.duration) {
                    self.current_time = 0;
                    self.state = .finished;
                } else self.current_time = self.duration - elapsed;
            },
        }
    }

    // UTILS ------------------------------------------------------------------------
    pub fn formatTime(nanos: i64, allocator: std.mem.Allocator) ![]u8 {
        const total_seconds = @divFloor(nanos, 1_000_000_000);
        const hours = @divFloor(total_seconds, 3600);
        const minutes = @divFloor(total_seconds, 60);
        const seconds = @mod(total_seconds, 60);
        const milliseconds = @divFloor(@mod(nanos, 1_000_000_000), 1_000_000);
        return std.fmt.allocPrint(allocator, "{d:0>2}{d:0>2}:{d:0>2}.{d:0>3}", .{ hours, minutes, seconds, milliseconds });
    }

    pub fn nanosToSeconds(nanos: i64) f32 {
        return @as(f32, @floatFromInt(nanos)) / 1_000_000_000.0;
    }

    pub fn secondsToNanos(seconds: f32) i64 {
        return @intFromFloat(seconds * 1_000_000_000.0);
    }
};
