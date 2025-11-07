const std = @import("std");
const ui = @import("./ui.zig");
const timer_mod = @import("timer");
const input_handler_mod = @import("input");
const storage_manager_mod = @import("storage");

pub const Game = struct {
    timer: timer_mod.Timer,
    storage: storage_manager_mod.StorageManager,
    input_handler: input_handler_mod.InputHandler,

    pub fn init(allocator: std.mem.Allocator) !Game {
        var storage = try storage_manager_mod.StorageManager.init(allocator);
        const saved_time = storage.getInt(.user, "game_time") orelse 0;
        var game = Game{
            .storage = storage,
            .input_handler = try input_handler_mod.InputHandler.init(allocator),
            .timer = timer_mod.Timer.init(.continuous, 0, 0),
        };

        const saved_time_ns = @as(i64, @intCast(saved_time));
        game.timer.state = .running;
        game.timer.current_time = saved_time_ns;
        game.timer.start_time = @as(i64, @intCast(std.time.nanoTimestamp())) - saved_time_ns;

        return game;
    }

    pub fn deinit(self: *Game) void {
        self.storage.deinit();
        self.input_handler.deinit();
    }

    pub fn draw(self: *Game) void {
        ui.drawDev(&self.storage, &self.input_handler, &self.timer);
    }

    pub fn update(self: *Game) void {
        self.timer.update();
        self.input_handler.update();

        const dev_pressed = self.input_handler.getPressedDevKeys();
        defer std.heap.c_allocator.free(dev_pressed);
        if (dev_pressed.len > 0) {
            const current_time = @as(u64, @intCast(self.timer.getElapsedTime()));
            const name = self.storage.getString(.user, "name") orelse "Player";
            const user_data = storage_manager_mod.UserData{ .name = name, .game_time = current_time };
            self.storage.save(storage_manager_mod.Data{ .user = user_data }, "user.json") catch |err| {
                std.debug.print("Failed to save game: {}\n", .{err});
            };
        }
    }
};
