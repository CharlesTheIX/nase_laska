const std = @import("std");
const rl = @import("raylib");
const nl = @import("nase_laska");

pub fn main() !void {
    rl.setTargetFPS(60);
    rl.initWindow(800, 450, "Nase Laska");
    defer rl.closeWindow();

    var game = try nl.Game.init(std.heap.c_allocator);
    defer game.deinit();

    while (!rl.windowShouldClose()) {
        game.update();
        rl.beginDrawing();
        rl.clearBackground(rl.Color.white);
        game.draw();
        rl.endDrawing();
    }
}
