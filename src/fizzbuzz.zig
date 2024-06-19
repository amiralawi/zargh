const std = @import("std");
const za = @import("zargh.zig");

// sample argument parsing

pub const FizzBuzzDescriptor = struct {
    const Self = @This();

    fizz: za.Option = .{ .short = 'f', .help = "print a fizz", .action = fizz },
    buzz: za.Option = .{ .long = "buzz", .help = "print a buzz", .action = buzz, .argument = .optional },
    fizzbuzz: za.Option = .{ .long = "fizzbuzz", .help = "increment fizzbuzz counter", .action = za.Option.Actions.incrementCount, .argument = .optional },
    help: za.Option = .{ .short = 'h', .long = "help", .help = "print this menu and exit", .action = usage },

    pub fn fizz(context: *anyopaque, opt: *za.Option) void {
        za.Option.Actions.incrementCount(context, opt);
        std.debug.print("fizz!\r\n", .{});
    }
    pub fn buzz(context: *anyopaque, opt: *za.Option) void {
        _ = opt;
        const ctx: *FizzBuzzDescriptor = @alignCast(@ptrCast(context));
        if (ctx.buzz.value) |arg| {
            std.debug.print("buzz! {s}\r\n", .{arg});
        } else {
            std.debug.print("buzz!\r\n", .{});
        }
        ctx.buzz.value = null;
    }
    pub fn usage(context: *anyopaque, opt: *za.Option) void {
        _ = context; // autofix
        _ = opt;
        const pre =
            \\fizzbuzz: fizzbuzz [-fh] [--buzz]
            \\
            \\Prints "fizz" or "buzz" to standard output.
            \\
            \\Options:
        ;

        std.debug.print("{s}\r\n", .{pre});
        std.debug.print("{s}\r\n", .{za.Parser(Self).helpstr});
    }
};

pub fn main() !void {
    // example usage: zig-out/bin/fizzbuzz -f --buzz=32 --fizzbuzz -f -f --buzz -fff --fizzbuzz

    // 1 - get all command-line arguments
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const heapalloc = arena.allocator();

    var args = try za.getArgs(heapalloc);

    // 2 - init a parser & descriptor: desc will hold command-line processing state
    var desc = FizzBuzzDescriptor{};
    var parser = za.Parser(FizzBuzzDescriptor).init(&desc);

    // 3 - pretty typical zargh loop
    for (args.items[1..]) |arg| {
        if (parser.parse(arg)) |_| {
            if (desc.help.flag) {
                return;
            }
        } else |err| {
            std.debug.print("  ->error arg='{s}' ({any})\r\n", .{ arg, err });
        }
    }

    std.debug.print("\r\nreport:\r\n", .{});
    std.debug.print("  nfizz     = {d}\r\n", .{desc.fizz.count});
    std.debug.print("  nbuzz     = {d}\r\n", .{desc.buzz.count});
    std.debug.print("  nfizzbuzz = {d}\r\n", .{desc.fizzbuzz.count});
}
