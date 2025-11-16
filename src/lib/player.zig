const input_mod = @import("input");
const rl = @import("raylib");
const std = @import("std");
const storage_mod = @import("storage");
const timer_mod = @import("timer");
const ui = @import("./ui.zig");

pub const Player = struct {
    cool_down_timer: timer_mod.Timer,
    input_handler: input_mod.InputHandler,
    hit_box: rl.Rectangle = rl.Rectangle{ .x = 0, .y = 0, .width = 50, .height = 50 },
    name: [:0]const u8 = "Player",
    position: rl.Vector2 = rl.Vector2{ .x = 100, .y = 100 },
    shader: rl.Color = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 255 },
    storage: storage_mod.StorageManager,

    pub fn init(storage: storage_mod.StorageManager, input_handler: input_mod.InputHandler) !Player {
        var player = Player{
            .input_handler = input_handler,
            .storage = storage,
            .cool_down_timer = timer_mod.Timer.init(.countdown, 0, 0),
        };
        player.load();
        return player;
    }

    pub fn deinit(self: *Player) void {
        self.cool_down_timer.deinit();
    }

    // METHODS ------------------------------------------------------------------------
    pub fn draw(self: *Player) void {
        ui.drawRectangleRec(self.hit_box, self.shader);
    }

    pub fn load(self: *Player) void {
        self.name = self.storage.getString(.user, "name") orelse self.name;
    }

    pub fn save(self: *Player, game_time: i64) void {
        self.storage.save(
            storage_mod.Data{
                .user = storage_mod.UserData{
                    .name = self.name,
                    .game_time = game_time,
                },
            },
            "user.json",
        ) catch |err| {
            std.debug.print("Failed to save game: {}\n", .{err});
        };
    }

    pub fn update(self: *Player) void {
        _ = self;
    }
};
