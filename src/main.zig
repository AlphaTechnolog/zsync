const std = @import("std");
const Arguments = @import("arguments.zig").Arguments;
const Files = @import("files.zig").Files;

fn help() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("zsync <source> <dest>\n", .{});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var arguments = try Arguments.from_arguments(allocator);
    defer arguments.deinit();

    if (arguments.*.source == null or arguments.*.dest == null) {
        try help();
        std.process.exit(1);
    }

    var files = try Files.new(
        allocator,
        arguments.*.source.?,
        arguments.*.dest.?,
    );

    defer files.deinit();

    files.merge(null) catch {
        const stderr = std.io.getStdErr().writer();
        try stderr.print("cannot merge files... aborting.\n", .{});
    };
}
