const std = @import("std");

pub const Files = struct {
    source: []const u8,
    dest: []const u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn new(allocator: std.mem.Allocator, source: []const u8, dest: []const u8) !*Self {
        var files = try allocator.create(Self);

        files.* = Self{
            .source = source,
            .dest = dest,
            .allocator = allocator,
        };

        return files;
    }

    fn file_exists(filename: []const u8) !bool {
        std.fs.cwd().access(filename, .{}) catch |x| {
            switch (x) {
                std.fs.Dir.AccessError.FileNotFound => return false,
                else => return x,
            }
        };

        return true;
    }

    fn different_files(a: []const u8, b: []const u8) !bool {
        const source_file = try std.fs.cwd().openFile(a, .{});
        const dest_file = try std.fs.cwd().openFile(b, .{});

        var source_buf: [1024]u8 = undefined;
        var dest_buf: [1024]u8 = undefined;

        const source_bytes = try source_file.readAll(source_buf[0..]);
        const dest_bytes = try dest_file.readAll(dest_buf[0..]);

        if (source_bytes != dest_bytes)
            return true;

        const source_contents = source_buf[0..source_bytes];
        const dest_contents = source_buf[0..dest_bytes];

        return !std.mem.eql(u8, source_contents, dest_contents);
    }

    pub fn merge(self: *Self, base_folder: ?[]const u8) !void {
        var root: ?[]const u8 = base_folder;
        if (root == null) {
            root = self.source;
        }

        var dir = std.fs.cwd().openIterableDir(root.?, .{}) catch |x| {
            const stderr = std.io.getStdErr().writer();
            stderr.print("cannot open path {s}\n", .{root.?}) catch unreachable;
            return x;
        };

        var dir_iterator = dir.iterate();
        defer dir.close();

        const stdout = std.io.getStdOut().writer();

        while (try dir_iterator.next()) |dir_content| {
            if (dir_content.kind != .directory and dir_content.kind != .file) {
                const stderr = std.io.getStdErr().writer();
                try stderr.print("Invalid file type found for {s}, skipping...", .{dir_content.name});
                continue;
            }

            var source_path = try std.fmt.allocPrint(self.allocator, "{s}/{s}", .{ root.?, dir_content.name });
            defer self.allocator.free(source_path);

            var dest_path_buf: [256]u8 = undefined;
            _ = std.mem.replace(u8, source_path, self.source, self.dest, dest_path_buf[0..]);

            const replacement_size = std.mem.replacementSize(u8, source_path, self.source, self.dest);
            var dest_path = dest_path_buf[0..replacement_size];

            if (dir_content.kind == .directory) {
                var exists = false;

                std.fs.cwd().makeDir(dest_path) catch |x| {
                    switch (x) {
                        std.os.MakeDirError.FileNotFound => {
                            const stderr = std.io.getStdErr().writer();
                            stderr.print("cannot open {s}\n", .{dest_path}) catch unreachable;
                            return x;
                        },
                        std.os.MakeDirError.PathAlreadyExists => {
                            exists = true;
                        },
                        else => return x,
                    }
                };

                if (!exists) {
                    try stdout.print("+ mkdir {s}\n", .{dest_path});
                }

                try self.merge(source_path);

                continue;
            }

            // doing nested if, to reduce files-opening
            if (try Self.file_exists(dest_path))
                if (!try Self.different_files(source_path, dest_path))
                    continue;

            // extracting dirname and filename from path
            const source_dir = source_path[0 .. source_path.len - dir_content.name.len];
            const dest_dir = dest_path[0 .. dest_path.len - dir_content.name.len];
            const source_filename = source_path[source_dir.len..source_path.len];
            const dest_filename = dest_path[dest_dir.len..dest_path.len];

            var opened_src_dir = try std.fs.cwd().openDir(source_dir, .{});
            var opened_dest_dir = try std.fs.cwd().openDir(dest_dir, .{});

            defer opened_src_dir.close();
            defer opened_dest_dir.close();

            try stdout.print("+ cp {s} -> {s}\n", .{ source_path, dest_path });
            try opened_src_dir.copyFile(source_filename, opened_dest_dir, dest_filename, .{});
        }
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
};
