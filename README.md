# zargh
Zig argument parsing with struct-based configuration.



## How It Works
Runtime behavior is generated at compile time based on an input context struct.  This struct is analyzed at compile time for any zargh.Option member variables: behavior is generated based on the default values for these member variables.  Because default values are known at compile time, the compiler can optimize away a lot of overhead that would be present in a system such as GNU's getopt library.

## Features
- Both long and short options can take arguments.  Arguments can be required or optional - values are stored as string, so can be converted to any datatype as required.
- Long options can use either `--option=value` or `--option value` syntax
- Short options are specified with `-` and can be chained ala `-abd`.  The last short option in a chain can accept an argument: `-abc=123` stores the string "123" into option c's value variable.
- Special behavior can be executed using a supplied action callback
- GNU-like `--` handling: argument scanning is bypassed after the first `--` encountered *unless* this is being supplied as an argument to an option.
- Automatically generated help strings

## Example

```zig
const std = @import("std");
const za = @import("zargh.zig");

const argContext = struct {
    const Self = @This();

    fizz: za.Option = .{ .short = 'f', .help = "print a fizz", .action = fizz },
    buzz: za.Option = .{ .long = "buzz", .help = "print a buzz", .action = buzz },
    help: za.Option = .{ .long = "help", .help = "display this menu and exit", .action = dispUsage },

    pub fn fizz(ctx: *anyopaque, opt: *za.Option) void {
        _ = ctx;
        _ = opt;
        std.debug.print("fizz!\r\n", .{});
    }

    pub fn buzz(ctx: *anyopaque, opt: *za.Option) void {
        _ = ctx;
        _ = opt;
        std.debug.print("buzz!\r\n", .{});
    }

    pub fn dispUsage(ctx: *anyopaque, opt: *za.Option) void {
        _ = ctx;
        _ = opt;
        std.debug.print("fizzbuzz options:\r\n", .{});
        std.debug.print("{s}\r\n", .{za.Parser(Self).helpstr});
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const heapalloc = arena.allocator();

    // 1 - get all command-line arguments
    var args: std.ArrayList([]const u8) = try za.getArgs(heapalloc);

    // 2 - init a parser & descriptor: desc will hold command-line processing state
    var desc = argContext{};
    var parser = za.Parser(argContext).init(&desc);

    // 3 - pretty typical zargh loop
    for (args.items[1..]) |arg| {
        _ = parser.parse(arg) catch {};
    }
}
