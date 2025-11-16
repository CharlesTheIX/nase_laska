const std = @import("std");
const storage_mod = @import("storage");
const timer_mod = @import("timer");

pub const GameTimer = struct {
    storage: storage_mod.StorageManager,
    timer: timer_mod.Timer,

    pub fn init(storage: storage_mod.StorageManager) !GameTimer {
        var game_timer = GameTimer{
            .storage = storage,
            .timer = timer_mod.Timer.init(.continuous, 0, 0),
        };
        game_timer.load();
        return game_timer;
    }

    pub fn deinit(self: *GameTimer) void {
        _ = self;
    }

    // METHODS ------------------------------------------------------------------------
    pub fn draw(self: *GameTimer) void {
        _ = self;
    }

    pub fn load(self: *GameTimer) void {
        const saved_time = self.storage.getInt(.user, "game_time") orelse 0;
        const saved_time_ns = @as(i64, @intCast(saved_time));
        self.timer.current_time = saved_time_ns;
        self.timer.start_time = @as(i64, @intCast(std.time.nanoTimestamp())) - saved_time_ns;
    }

    pub fn update(self: *GameTimer) void {
        self.timer.update();
    }
};
