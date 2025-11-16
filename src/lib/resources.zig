const std = @import("std");
const storage_mod = @import("storage");
const timer_mod = @import("timer");

pub const ResourceName = enum {
    img_spritesheet,
    img_world_1,
    snd_spritesheet,
    snd_world_1,
};

pub const ResourceType = enum { image, sound };

pub const Resources = struct {
    sounds: std.AutoHashMap([]const u8, usize),
    storage: storage_mod.StorageManager,
    textures: std.AutoHashMap([]const u8, usize),

    pub fn init(storage: storage_mod.StorageManager) !Resources {
        const resources = Resources{
            .sounds = std.AutoHashMap([]const u8, usize).init(std.heap.c_allocator),
            .storage = storage,
            .textures = std.AutoHashMap([]const u8, usize).init(std.heap.c_allocator),
        };

        return resources;
    }

    pub fn deinit(self: *Resources) void {
        self.sounds.deinit();
        self.textures.deinit();
    }

    // METHODS ------------------------------------------------------------------------
    pub fn load(self: *Resources, resource_type: ResourceType, name: ResourceName) void {
        // const filename = Resources.getFilename(resource_type, name);

        // switch (resource_type) {
        //     .image => {
        //         const texture_id = 0; // Placeholder for actual texture loading
        //         _ = self.textures.put(filename, texture_id);
        //     },
        //     .sound => {
        //         const sound_id = 0; // Placeholder for actual sound loading
        //         _ = self.sounds.put(filename, sound_id);
        //     },
        // }
        _ = name;
        _ = self;
        _ = resource_type;
    }

    // UTILS ------------------------------------------------------------------------
    pub fn getFilename(resource_type: ResourceType, name: ResourceName) []const u8 {
        return switch (resource_type) {
            .image => switch (name) {
                .img_spritesheet => "spritesheet.png",
                .img_world_1 => "world_1.png",
            },
            .sound => switch (name) {
                .snd_spritesheet => "spritesheet.wav",
                .snd_world_1 => "world_1.wav",
            },
        };
    }
};
