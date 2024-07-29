const std = @import("std");
const Pkg = std.build.Pkg;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Get the ERTS_INCLUDE_DIR passed by the :build_dot_zig compiler
    // If the variable is not found, fallback to the Elixir shell so this also
    // works when manually invoking zig build or using this from zls
    const erts_include_dir = std.process.getEnvVarOwned(b.allocator, "ERTS_INCLUDE_DIR") catch
        erts_include_dir_from_elixir(b);

    const exwire_nif = b.addSharedLibrary(.{
        .name = "exwire_nif",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/root.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
    });

    const exe = b.addExecutable(.{
        .name = "pcap_zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.addIncludePath(.{ .cwd_relative = erts_include_dir });
    exe.linkLibC();

    const nif_step = b.step("exwire_lib", "Compiles erlang library");

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    // b.installArtifact(exe);
    //
    // // This *creates* a Run step in the build graph, to be executed when another
    // // step is evaluated that depends on it. The next line below will establish
    // // such a dependency.
    // const run_cmd = b.addRunArtifact(exe);
    //
    // // By making the run step depend on the install step, it will be run from the
    // // installation directory rather than directly from within the cache directory.
    // // This is not necessary, however, if the application depends on other installed
    // // files, this ensures they will be present and in the expected location.
    // run_cmd.step.dependOn(b.getInstallStep());
    //
    // // This allows the user to pass arguments to the application in the build
    // // command itself, like this: `zig build run -- arg1 arg2 etc`
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

    // // Creates a step for unit testing. This only builds the test executable
    // // but does not run it.
    // const lib_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    //
    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    //
    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    //
    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    //
    // // Similar to creating the run step earlier, this exposes a `test` step to
    // // the `zig build --help` menu, providing a way for the user to request
    // // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
    // test_step.dependOn(&run_exe_unit_tests.step);

    // Add ERTS include dir to the includes
    exwire_nif.addIncludePath(.{ .cwd_relative = erts_include_dir });
    // This is needed to avoid errors at link time on MacOS
    // exwire_nif.linker_allow_shlib_undefined = true;

    exwire_nif.linkLibC();
    nif_step.dependOn(&exwire_nif.step);
    nif_step.dependOn(&exe.step);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(exwire_nif);
    b.installArtifact(exe);
}

// Retrieves the location of the ERTS include dir from Elixir
fn erts_include_dir_from_elixir(b: *std.Build) []const u8 {
    const argv = [_][]const u8{
        "elixir",
        "--eval",
        \\["#{:code.root_dir()}", "erts-#{:erlang.system_info(:version)}", "include"]
        \\|> Path.join()
        \\|> IO.write()
    };

    return b.run(&argv);
}
