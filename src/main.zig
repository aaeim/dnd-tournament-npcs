const std = @import("std");
const dnd_tournament_npcs = @import("dnd_tournament_npcs");
const NPC = @import("my_types.zig").NPC;
const ops = @import("operations.zig");
const print = std.debug.print;

pub fn main() !void {
    var npcs = [32]NPC{
        .{ .id = 0, .name = "Frodo", .hp = 100, .party_id = 0, .zone_id = 3 },
        .{ .id = 1, .name = "Sam", .hp = 100, .party_id = 0, .zone_id = 3 },
        .{ .id = 2, .name = "Legolas", .hp = 100, .party_id = 0, .zone_id = 3 },
        .{ .id = 3, .name = "Aragorn", .hp = 100, .party_id = 0, .zone_id = 3 },
        .{ .id = 4, .name = "Gimli", .hp = 100, .party_id = 0, .zone_id = 3 },

        .{ .id = 5, .name = "Harry", .hp = 100, .party_id = 1, .zone_id = 2 },
        .{ .id = 6, .name = "Ron", .hp = 100, .party_id = 1, .zone_id = 2 },
        .{ .id = 7, .name = "Hermione", .hp = 100, .party_id = 1, .zone_id = 2 },
        .{ .id = 8, .name = "Hagrid", .hp = 100, .party_id = 1, .zone_id = 2 },
        .{ .id = 9, .name = "Griffin", .hp = 100, .party_id = 1, .zone_id = 2 },

        .{ .id = 10, .name = "Khaleesi", .hp = 100, .party_id = 2, .zone_id = 4 },
        .{ .id = 11, .name = "Dragon", .hp = 100, .party_id = 2, .zone_id = 4 },
        .{ .id = 12, .name = "Jon", .hp = 100, .party_id = 2, .zone_id = 4 },
        .{ .id = 13, .name = "Aria", .hp = 100, .party_id = 2, .zone_id = 4 },

        .{ .id = 14, .name = "Geralt", .hp = 100, .party_id = 3, .zone_id = 2 },
        .{ .id = 15, .name = "Jennefer", .hp = 100, .party_id = 3, .zone_id = 2 },
        .{ .id = 16, .name = "Jaskier", .hp = 100, .party_id = 3, .zone_id = 2 },
        .{ .id = 17, .name = "Ciri", .hp = 100, .party_id = 3, .zone_id = 2 },

        .{ .id = 18, .name = "Link", .hp = 100, .party_id = 4, .zone_id = 3 },
        .{ .id = 19, .name = "Zelda", .hp = 100, .party_id = 4, .zone_id = 3 },
        .{ .id = 20, .name = "Mario", .hp = 100, .party_id = 4, .zone_id = 3 },
        .{ .id = 21, .name = "Luigi", .hp = 100, .party_id = 4, .zone_id = 3 },

        .{ .id = 22, .name = "Shadowheart", .hp = 100, .party_id = 5, .zone_id = 1 },
        .{ .id = 23, .name = "Karlach", .hp = 100, .party_id = 5, .zone_id = 1 },
        .{ .id = 24, .name = "Laezel", .hp = 100, .party_id = 5, .zone_id = 1 },
        .{ .id = 25, .name = "Astarion", .hp = 100, .party_id = 5, .zone_id = 1 },
        .{ .id = 26, .name = "Gale", .hp = 100, .party_id = 5, .zone_id = 1 },

        .{ .id = 27, .name = "Groot", .hp = 100, .party_id = 6, .zone_id = 1 },
        .{ .id = 28, .name = "Rocket", .hp = 100, .party_id = 6, .zone_id = 1 },
        .{ .id = 29, .name = "Peter", .hp = 100, .party_id = 6, .zone_id = 1 },
        .{ .id = 30, .name = "Drax", .hp = 100, .party_id = 6, .zone_id = 1 },
        .{ .id = 31, .name = "Gamorra", .hp = 100, .party_id = 6, .zone_id = 1 },
    };

    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));
    var prng = std.Random.DefaultPrng.init(seed);
    const dice = prng.random();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var zones: [4]std.ArrayList(*NPC) = undefined;

    for (&zones) |*z| {
        z.* = try std.ArrayList(*NPC).initCapacity(allocator, 4);
    }

    defer for (&zones) |*z| {
        z.deinit(allocator);
    };

    try ops.updateZones(npcs[0..], zones[0..], allocator);
    const test_zones = [4]u8{ 1, 2, 3, 4 };
    try ops.printZones(test_zones[0..], zones[0..]);

    var buff: [10]u8 = undefined;
    var in_wrapper = std.fs.File.stdin().reader(&buff);
    const in: *std.Io.Reader = &in_wrapper.interface;

    var quit: bool = false;
    var rounds: u8 = 1;

    print("Let the tournament begin!\n> ", .{});
    while (!quit) {
        const str = try in.peekDelimiterExclusive('\n');
        var it = std.mem.tokenizeAny(u8, str, " \t");
        if (it.next()) |token| {
            if (std.mem.eql(u8, token, "r")) {
                if (it.next()) |val| {
                    if (val.len == 4) {
                        const zs = try ops.parseZones(val);
                        try ops.rollAndUpdate(zs, npcs[0..], zones[0..], allocator, dice);
                        print("======== Round {} ========\n", .{rounds});
                        try ops.printZones(test_zones[0..], zones[0..]);
                        rounds += 1;
                    } else {
                        print("Needs 4 zones! {s} \n", .{val});
                    }
                } else {
                    print("r needs a value! try 1111\n", .{});
                }
            } else if (std.mem.eql(u8, token, "e")) {
                if (it.next()) |id_str| {
                    if (it.next()) |hp_str| {
                        const id = try std.fmt.parseUnsigned(u8, id_str, 10);
                        const hp = try std.fmt.parseUnsigned(u16, hp_str, 10);
                        const npc = ops.getNPC(id, npcs[0..]);
                        if (npc) |unw| unw.hp = hp;
                        try ops.printZones(test_zones[0..], zones[0..]);
                    } else {
                        print("missing hp value!\n", .{});
                    }
                } else {
                    print("e needs a character id!\n", .{});
                }
            } else if (std.mem.eql(u8, token, "q")) {
                quit = true;
            }
        }
        if (quit) break;
        print("> ", .{});
        in.toss(str.len + 1);
    }
}
