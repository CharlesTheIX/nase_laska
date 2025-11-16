const game_timer_mod = @import("./game_timer.zig");
const input_mod = @import("input");
const player_mod = @import("./player.zig");
const std = @import("std");
const storage_mod = @import("storage");
const ui = @import("./ui.zig");

pub const Game = struct {
    input_handler: input_mod.InputHandler,
    player: player_mod.Player,
    storage: storage_mod.StorageManager,
    timer: game_timer_mod.GameTimer,

    pub fn init(allocator: std.mem.Allocator) !Game {
        const storage = try storage_mod.StorageManager.init(allocator);
        return Game{
            .input_handler = try input_mod.InputHandler.init(allocator),
            .player = try player_mod.Player.init(storage),
            .storage = storage,
            .timer = try game_timer_mod.GameTimer.init(storage),
        };
    }

    pub fn deinit(self: *Game) void {
        self.timer.deinit();
        self.player.deinit();
        self.storage.deinit();
        self.input_handler.deinit();
    }

    // METHODS ------------------------------------------------------------------------
    pub fn draw(self: *Game) void {
        ui.drawDev(&self.storage, &self.input_handler, &self.timer.timer);
    }

    pub fn load(self: *Game) void {
        self.timer.load();
        self.player.load();
    }

    pub fn update(self: *Game) void {
        self.timer.update();
        self.input_handler.update();
        const dev_pressed = self.input_handler.getPressedDevKeys();
        defer std.heap.c_allocator.free(dev_pressed);

        if (dev_pressed.len > 0) {
            switch (self.timer.timer.state) {
                .paused => self.timer.timer.unpause(),
                .running => self.timer.timer.pause(),
                .stopped => self.timer.timer.start(),
                else => {},
            }
            self.player.save(self.timer.timer.getElapsedTime());
        }
    }
};
