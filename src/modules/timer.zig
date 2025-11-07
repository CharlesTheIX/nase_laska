const std = @import("std");

pub const TimerType = enum { countdown, continuous };

pub const TimerState = enum { stopped, running, paused, finished };

// Time values in nanoseconds
pub const Timer = struct {
    limit: i64 = 0,
    duration: i64 = 0,
    start_time: i64 = 0,
    paused_time: i64 = 0,
    timer_type: TimerType,
    current_time: i64 = 0,
    state: TimerState = .stopped,

    pub fn init(timer_type: TimerType, duration: i64, limit: i64) Timer {
        return Timer{
            .limit = limit,
            .duration = duration,
            .timer_type = timer_type,
        };
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
        self.start_time = @intCast(std.time.nanoTimestamp());
        if (self.timer_type == .countdown and self.current_time == 0) self.current_time = self.duration;
    }

    pub fn pause(self: *Timer) void {
        if (self.state == .running) {
            self.state = .paused;
            self.paused_time = @intCast(std.time.nanoTimestamp());
        }
    }

    pub fn unpause(self: *Timer) void {
        if (self.state == .paused) {
            const paused_duration = @as(i64, @intCast(std.time.nanoTimestamp() - self.paused_time));
            self.state = .running;
            self.start_time += paused_duration;
        }
    }

    pub fn stop(self: *Timer) void {
        self.state = .stopped;
    }

    pub fn reset(self: *Timer) void {
        self.start_time = 0;
        self.paused_time = 0;
        self.state = .stopped;

        if (self.timer_type == .countdown) {
            self.current_time = self.duration;
        } else {
            self.current_time = 0;
        }
    }

    pub fn update(self: *Timer) void {
        if (self.state != .running) return;
        const now = std.time.nanoTimestamp();
        const total_elapsed = now - self.start_time;
        switch (self.timer_type) {
            .countdown => {
                const elapsed = @as(i64, @intCast(total_elapsed));
                if (elapsed >= self.duration) {
                    self.current_time = 0;
                    self.state = .finished;
                } else {
                    self.current_time = self.duration - elapsed;
                }
            },
            .continuous => {
                self.current_time = @as(i64, @intCast(total_elapsed));
                if (self.limit > 0 and self.current_time >= self.limit) {
                    self.state = .finished;
                    self.current_time = self.limit;
                }
            },
        }
    }

    pub fn getElapsedTime(self: *Timer) i64 {
        if (self.state == .stopped) return 0;
        switch (self.timer_type) {
            .continuous => return self.current_time,
            .countdown => return self.duration - self.current_time,
        }
    }

    pub fn getRemainingTime(self: *Timer) i64 {
        if (self.timer_type != .countdown) return 0;
        return if (self.current_time > 0) self.current_time else 0;
    }

    pub fn getCurrentTime(self: *Timer) i64 {
        return self.current_time;
    }

    pub fn getProgress(self: *Timer) f32 {
        switch (self.timer_type) {
            .countdown => {
                if (self.duration == 0) return 0;
                return 1.0 - (@as(f32, @floatFromInt(self.current_time)) / @as(f32, @floatFromInt(self.duration)));
            },
            .continuous => {
                if (self.limit == 0) return 0;
                return @as(f32, @floatFromInt(self.current_time)) / @as(f32, @floatFromInt(self.limit));
            },
        }
    }

    pub fn isFinished(self: *Timer) bool {
        return self.state == .finished;
    }

    pub fn isRunning(self: *Timer) bool {
        return self.state == .running;
    }

    pub fn isPaused(self: *Timer) bool {
        return self.state == .paused;
    }

    pub fn secondsToNanos(seconds: f32) i64 {
        return @intFromFloat(seconds * 1_000_000_000.0);
    }

    pub fn nanosToSeconds(nanos: i64) f32 {
        return @as(f32, @floatFromInt(nanos)) / 1_000_000_000.0;
    }

    pub fn formatTime(nanos: i64, allocator: std.mem.Allocator) ![]u8 {
        const total_seconds = @divFloor(nanos, 1_000_000_000);
        const seconds = @mod(total_seconds, 60);
        const minutes = @divFloor(total_seconds, 60);
        const milliseconds = @divFloor(@mod(nanos, 1_000_000_000), 1_000_000);
        return std.fmt.allocPrint(allocator, "{d:0>2}:{d:0>2}.{d:0>3}", .{ minutes, seconds, milliseconds });
    }
};
