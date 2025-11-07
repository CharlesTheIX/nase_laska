const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{ .target = target, .optimize = optimize });
    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const storage_mod = b.addModule("storage", .{
        .target = target,
        .root_source_file = b.path("src/modules/storage.zig"),
    });

    const input_mod = b.addModule("input", .{
        .target = target,
        .root_source_file = b.path("src/modules/input.zig"),
        .imports = &.{.{ .name = "raylib", .module = raylib }},
    });

    const timer_mod = b.addModule("timer", .{
        .target = target,
        .root_source_file = b.path("src/modules/timer.zig"),
    });

    const mod = b.addModule("nase_laska", .{
        .target = target,
        .root_source_file = b.path("src/root.zig"),
        .imports = &.{
            .{ .name = "raylib", .module = raylib },
            .{ .name = "input", .module = input_mod },
            .{ .name = "timer", .module = timer_mod },
            .{ .name = "storage", .module = storage_mod },
        },
    });

    const exe = b.addExecutable(.{
        .name = "nase_laska",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "nase_laska", .module = mod },
                .{ .name = "input", .module = input_mod },
                .{ .name = "timer", .module = timer_mod },
                .{ .name = "storage", .module = storage_mod },
            },
        }),
    });
    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);
    b.installArtifact(exe);

    // Install templates directory
    const templates_path = b.path("templates");
    if (std.fs.cwd().access(templates_path.getPath(b), .{})) |_| {
        const templates_install = b.addInstallDirectory(.{
            .install_dir = .bin,
            .source_dir = templates_path,
            .install_subdir = "templates",
        });
        b.getInstallStep().dependOn(&templates_install.step);
    } else |_| {}

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| run_cmd.addArgs(args);
}
