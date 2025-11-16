const input_mod = @import("input");
const player_mod = @import("./player.zig");
const resources_mod = @import("./resources.zig");
const std = @import("std");
const storage_mod = @import("storage");
const timer_mod = @import("./game_timer.zig");

const GameState = enum {
    menu,
    playing,
    paused,
    game_over,
};

pub const Game = struct {
    input_handler: input_mod.InputHandler,
    player: player_mod.Player,
    resources: resources_mod.Resources,
    state: GameState,
    storage: storage_mod.StorageManager,
    timer: timer_mod.GameTimer,

    pub fn init(allocator: std.mem.Allocator) !Game {
        const storage = try storage_mod.StorageManager.init(allocator);
        const input_handler = try input_mod.InputHandler.init(allocator);
        return Game{
            .input_handler = input_handler,
            .player = try player_mod.Player.init(storage, input_handler),
            .resources = try resources_mod.Resources.init(storage),
            .state = .playing,
            .storage = storage,
            .timer = try timer_mod.GameTimer.init(storage),
        };
    }

    pub fn deinit(self: *Game) void {
        self.timer.deinit();
        self.player.deinit();
        self.storage.deinit();
        self.resources.deinit();
        self.input_handler.deinit();
    }

    // METHODS ------------------------------------------------------------------------
    pub fn draw(self: *Game) void {
        self.player.draw();
    }

    pub fn load(self: *Game) void {
        self.timer.load();
        self.player.load();
        self.resources.load();
    }

    pub fn update(self: *Game) void {
        self.timer.update();
        self.input_handler.update();
        self.player.update();

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

    pub fn updateState(self: *Game) void {
        if (self.input_handler.isPressed(.x)) {
            if (self.state == .playing) {
                self.state = .paused;
                self.timer.timer.pause();
            } else if (self.state == .paused) {
                self.state = .playing;
                self.timer.timer.unpause();
            }
        } else if (self.input_handler.isPressed(.c)) {
            self.state = .menu;
            self.timer.timer.stop();
        }
    }
};
