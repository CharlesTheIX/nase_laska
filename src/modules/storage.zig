const json = std.json;
const std = @import("std");

pub const Data = union(DataType) { user: UserData, world: WorldData };

pub const DataType = enum { user, world };

pub const UserData = struct { name: [:0]const u8, game_time: u64 };

pub const WorldData = struct { level: u32, score: u32 };

pub const StorageManager = struct {
    exe_dir: []const u8,
    save_dir: []const u8,
    user_data: ?UserData = null,
    world_data: ?WorldData = null,
    data_allocator: std.mem.Allocator,

    const user = "X";
    const _user = "user.json";

    pub fn deinit(self: *StorageManager) void {
        if (self.user_data) |ud| self.data_allocator.free(@constCast(ud.name));
        self.user_data = null;
        self.world_data = null;
        //NOTE: exe_dir and save_dir are freed by the parent allocator when StorageManager is destroyed
    }

    pub fn init(parent_allocator: std.mem.Allocator) !StorageManager {
        const cwd = ".";
        const exe_path = try std.fs.selfExePathAlloc(parent_allocator);
        const exe_dir = std.fs.path.dirname(exe_path) orelse cwd;
        const exe_dir_dup = try parent_allocator.dupe(u8, exe_dir);
        defer parent_allocator.free(exe_path);

        const home = std.process.getEnvVarOwned(parent_allocator, "HOME") catch std.process.getEnvVarOwned(parent_allocator, "USERPROFILE") catch return error.HomeDirNotFound;
        defer parent_allocator.free(home);

        const save_dir_name = ".nase_laska";
        const save_dir = if (std.mem.eql(u8, home, "/tmp"))
            try parent_allocator.dupe(u8, "/tmp/.nase_laska")
        else
            try std.fs.path.join(parent_allocator, &[_][]const u8{ home, save_dir_name });

        const save_dir_dup = try parent_allocator.dupe(u8, save_dir);
        std.fs.makeDirAbsolute(save_dir) catch {};
        defer parent_allocator.free(save_dir);

        return .{
            .exe_dir = exe_dir_dup,
            .save_dir = save_dir_dup,
            .data_allocator = parent_allocator,
        };
    }

    // ------------------------------------------------------------------------
    // METHODS
    // ------------------------------------------------------------------------
    fn dataToString(data: Data, allocator: std.mem.Allocator) ![]const u8 {
        return switch (data) {
            .user => |user_data| std.fmt.allocPrint(
                allocator,
                "{{\"name\": \"{s}\", \"game_time\": {d}}}",
                .{ user_data.name, user_data.game_time },
            ),
            .world => |world_data| std.fmt.allocPrint(
                allocator,
                "{{\"level\": {d}, \"score\": {d}}}",
                .{ world_data.level, world_data.score },
            ),
        };
    }

    pub fn getInt(self: *StorageManager, data_type: DataType, field: []const u8) ?u64 {
        std.debug.print("getInt called for field: {s}\n", .{field});
        const data = self.load(data_type, switch (data_type) {
            .user => "user.json",
            .world => "world.json",
        }) catch |err| {
            std.debug.print("load failed: {}\n", .{err});
            return null;
        };
        const result = switch (data) {
            .user => |u| if (std.mem.eql(u8, field, "game_time")) u.game_time else null,
            .world => |w| if (std.mem.eql(u8, field, "level")) @as(u64, w.level) else if (std.mem.eql(u8, field, "score")) @as(u64, w.score) else null,
        };
        std.debug.print("getInt returning: {any}\n", .{result});
        return result;
    }

    pub fn getString(self: *StorageManager, data_type: DataType, field: []const u8) ?[:0]const u8 {
        const data = self.load(data_type, switch (data_type) {
            .user => "user.json",
            .world => "world.json",
        }) catch return null;
        return switch (data) {
            .user => |u| if (std.mem.eql(u8, field, "name")) u.name else null,
            .world => null,
        };
    }

    pub fn load(self: *StorageManager, data_type: DataType, filename: []const u8) !Data {
        switch (data_type) {
            .user => {
                if (self.user_data) |data| return Data{ .user = data };

                const full_path = try std.fs.path.join(std.heap.c_allocator, &[_][]const u8{ self.save_dir, filename });
                defer std.heap.c_allocator.free(full_path);
                const file_exists = if (std.fs.openFileAbsolute(full_path, .{})) |f| blk: {
                    f.close();
                    break :blk true;
                } else |_| false;

                if (!file_exists) {
                    const template_data_union = try self.loadTemplateData(.user, filename);
                    const template_data = template_data_union.user;
                    self.user_data = template_data;
                    try self.save(Data{ .user = template_data }, filename);
                    return Data{ .user = template_data };
                }

                const file = try std.fs.openFileAbsolute(full_path, .{});
                defer file.close();

                const content = try file.readToEndAlloc(self.data_allocator, 1024 * 1024);
                const parsed = try stringToData(.user, content, self.data_allocator);
                defer self.data_allocator.free(content);
                self.user_data = parsed.user;

                return parsed;
            },
            .world => {
                if (self.world_data) |data| return Data{ .world = data };

                const full_path = try std.fs.path.join(std.heap.c_allocator, &[_][]const u8{ self.save_dir, filename });
                defer std.heap.c_allocator.free(full_path);
                const file_exists = if (std.fs.openFileAbsolute(full_path, .{})) |f| blk: {
                    f.close();
                    break :blk true;
                } else |_| false;

                if (!file_exists) {
                    const template_data_union = try self.loadTemplateData(.world, filename);
                    const template_data = template_data_union.world;
                    self.world_data = template_data;
                    try self.save(Data{ .world = template_data }, filename);
                    return Data{ .world = template_data };
                }

                const file = try std.fs.openFileAbsolute(full_path, .{});
                defer file.close();

                const content = try file.readToEndAlloc(self.data_allocator, 1024 * 1024);
                const parsed = try stringToData(.world, content, self.data_allocator);
                defer self.data_allocator.free(content);
                self.world_data = parsed.world;

                return parsed;
            },
        }
    }

    fn loadTemplateData(self: *StorageManager, data_type: DataType, filename: []const u8) !Data {
        const full_path = blk: {
            const templates_dir_name = "templates";
            const templates_dir = try std.fs.path.join(std.heap.c_allocator, &[_][]const u8{
                self.exe_dir,
                templates_dir_name,
            });
            defer std.heap.c_allocator.free(templates_dir);

            break :blk try std.fs.path.join(std.heap.c_allocator, &[_][]const u8{ templates_dir, filename });
        };
        defer std.heap.c_allocator.free(full_path);

        const file = try std.fs.openFileAbsolute(full_path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(self.data_allocator, 1024 * 1024);
        const result = try stringToData(data_type, content, self.data_allocator);
        defer self.data_allocator.free(content);

        return result;
    }

    pub fn save(self: *StorageManager, data: Data, filename: []const u8) !void {
        switch (data) {
            .user => |user_data| {
                self.user_data = user_data;
            },
            .world => |world_data| {
                self.world_data = world_data;
            },
        }

        const full_path = try std.fs.path.join(std.heap.c_allocator, &[_][]const u8{ self.save_dir, filename });
        const file = try std.fs.createFileAbsolute(full_path, .{});
        defer file.close();
        defer std.heap.c_allocator.free(full_path);

        const content = try dataToString(data, std.heap.c_allocator);
        try file.writeAll(content);
        std.heap.c_allocator.free(content);
    }

    fn stringToData(data_type: DataType, json_str: []const u8, allocator: std.mem.Allocator) !Data {
        switch (data_type) {
            .user => {
                var parsed = try json.parseFromSlice(UserData, allocator, json_str, .{});
                defer parsed.deinit();
                const name = try allocator.dupeZ(u8, parsed.value.name);
                return Data{ .user = .{ .name = name, .game_time = parsed.value.game_time } };
            },
            .world => {
                var parsed = try json.parseFromSlice(WorldData, allocator, json_str, .{});
                defer parsed.deinit();
                return Data{ .world = parsed.value };
            },
        }
    }
};
