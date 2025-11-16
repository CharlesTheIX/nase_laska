const std = @import("std");
const storage_mod = @import("storage");
const timer_mod = @import("timer");

pub const Player = struct {
    cool_down_timer: timer_mod.Timer,
    name: [:0]const u8 = "Player",
    storage: storage_mod.StorageManager,

    pub fn init(storage: storage_mod.StorageManager) !Player {
        var player = Player{
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
        _ = self;
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
