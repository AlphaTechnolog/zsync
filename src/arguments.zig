const std = @import("std");

pub const Arguments = struct {
    source: ?[]const u8,
    dest: ?[]const u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn from_arguments(allocator: std.mem.Allocator) !*Self {
        const args = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, args);

        var arguments = try allocator.create(Self);

        arguments.* = Arguments{ .source = null, .dest = null, .allocator = allocator };

        for (0.., args) |i, arg| {
            if (i == 0) continue;
            if (arguments.*.source == null) {
                arguments.*.source = try std.fmt.allocPrint(allocator, "{s}", .{arg});
                continue;
            }
            if (arguments.*.dest == null) {
                arguments.*.dest = try std.fmt.allocPrint(allocator, "{s}", .{arg});
                continue;
            }
        }

        return arguments;
    }

    pub fn deinit(self: *Self) void {
        if (self.*.source) |source| self.allocator.free(source);
        if (self.*.dest) |dest| self.allocator.free(dest);
        self.allocator.destroy(self);
    }
};
