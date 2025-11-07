const std = @import("std");
const rl = @import("raylib");

const Filter = enum { Any, All };

const KeySet = enum { All, Dev, Action, Movement };

pub const InputHandler = struct {
    allocator: std.mem.Allocator,
    dev_keys: []const rl.KeyboardKey,
    action_keys: []const rl.KeyboardKey,
    movement_keys: []const rl.KeyboardKey,
    pressed_keys: std.AutoHashMap(rl.KeyboardKey, void),

    pub fn init(allocator: std.mem.Allocator) !InputHandler {
        const dev_keys = &[_]rl.KeyboardKey{.z};
        const action_keys = &[_]rl.KeyboardKey{ .space, .enter };
        const movement_keys = &[_]rl.KeyboardKey{ .w, .a, .s, .d };
        const pressed_keys = std.AutoHashMap(rl.KeyboardKey, void).init(allocator);

        return .{
            .allocator = allocator,
            .dev_keys = dev_keys,
            .action_keys = action_keys,
            .movement_keys = movement_keys,
            .pressed_keys = pressed_keys,
        };
    }

    pub fn deinit(self: *InputHandler) void {
        self.pressed_keys.deinit();
    }

    // ------------------------------------------------------------------------
    // METHODS
    // ------------------------------------------------------------------------
    pub fn getPressedActionKeys(self: *InputHandler) []rl.KeyboardKey {
        var keys = std.ArrayList(rl.KeyboardKey).initCapacity(self.allocator, 2) catch return &[_]rl.KeyboardKey{};
        defer keys.deinit(self.allocator);

        for (self.action_keys) |key| {
            if (self.pressed_keys.contains(key)) keys.append(self.allocator, key) catch {};
        }

        return keys.toOwnedSlice(self.allocator) catch &[_]rl.KeyboardKey{};
    }

    pub fn getPressedMovementKeys(self: *InputHandler) []rl.KeyboardKey {
        var keys = std.ArrayList(rl.KeyboardKey).initCapacity(self.allocator, 4) catch return &[_]rl.KeyboardKey{};
        defer keys.deinit(self.allocator);

        for (self.movement_keys) |key| {
            if (self.pressed_keys.contains(key)) keys.append(self.allocator, key) catch {};
        }

        return keys.toOwnedSlice(self.allocator) catch &[_]rl.KeyboardKey{};
    }

    pub fn getPressedDevKeys(self: *InputHandler) []rl.KeyboardKey {
        var keys = std.ArrayList(rl.KeyboardKey).initCapacity(self.allocator, 2) catch return &[_]rl.KeyboardKey{};
        defer keys.deinit(self.allocator);

        for (self.dev_keys) |key| {
            if (self.pressed_keys.contains(key)) keys.append(self.allocator, key) catch {};
        }

        return keys.toOwnedSlice(self.allocator) catch &[_]rl.KeyboardKey{};
    }

    pub fn isActionPressed(self: *InputHandler, key: rl.KeyboardKey) bool {
        return self.isPressed(key) and std.mem.indexOfScalar(rl.KeyboardKey, self.action_keys, key) != null;
    }

    pub fn isMovementPressed(self: *InputHandler, key: rl.KeyboardKey) bool {
        return self.isPressed(key) and std.mem.indexOfScalar(rl.KeyboardKey, self.movement_keys, key) != null;
    }

    pub fn isPressed(self: *InputHandler, key: rl.KeyboardKey) bool {
        return self.pressed_keys.contains(key);
    }

    pub fn update(self: *InputHandler) void {
        self.pressed_keys.clearRetainingCapacity();
        for (self.dev_keys) |key| {
            if (rl.isKeyDown(key)) self.pressed_keys.put(key, {}) catch {};
        }

        for (self.movement_keys) |key| {
            if (rl.isKeyDown(key)) self.pressed_keys.put(key, {}) catch {};
        }

        for (self.action_keys) |key| {
            if (rl.isKeyDown(key)) self.pressed_keys.put(key, {}) catch {};
        }
    }
};
