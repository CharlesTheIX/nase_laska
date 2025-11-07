const std = @import("std");
const rl = @import("raylib");
const timer_mod = @import("timer");
const input_mod = @import("input");
const storage_manager_mod = @import("storage");

pub fn drawText(text: [:0]const u8, posX: i32, posY: i32, fontSize: i32, color: rl.Color) void {
    rl.drawText(text, posX, posY, fontSize, color);
}

pub fn drawDev(storage: *storage_manager_mod.StorageManager, input_handler: *input_mod.InputHandler, timer: *timer_mod.Timer) void {
    const name = storage.getString(.user, "name") orelse "Guest";
    drawText(name, 100, 100, 20, rl.Color.black);

    const movement_pressed = input_handler.getPressedMovementKeys();
    defer std.heap.c_allocator.free(movement_pressed);
    const action_pressed = input_handler.getPressedActionKeys();
    defer std.heap.c_allocator.free(action_pressed);

    var input_buf: [128:0]u8 = undefined;
    const input_text = std.fmt.bufPrintZ(&input_buf, "Movement: {} Action: {}", .{ movement_pressed.len, action_pressed.len }) catch "Input: N/A";
    drawText(input_text, 100, 160, 20, rl.Color.blue);

    const elapsed_seconds = timer_mod.Timer.nanosToSeconds(timer.getElapsedTime());
    var timer_buf: [256:0]u8 = undefined;
    const timer_status = if (timer.isFinished()) "FINISHED" else if (timer.isPaused()) "PAUSED" else "RUNNING";
    const timer_text = std.fmt.bufPrintZ(&timer_buf, "Game Time: {d:.1}s | Status: {s}", .{ elapsed_seconds, timer_status }) catch "Timer: Error";
    drawText(timer_text, 100, 200, 16, rl.Color.green);
}
