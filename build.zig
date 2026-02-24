const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("main.zig"),
        .optimize = optimize,
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "myepraht",
        .root_module = mod,
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "run the app");

    const run = b.addRunArtifact(exe);
    run_step.dependOn(&run.step);
}
