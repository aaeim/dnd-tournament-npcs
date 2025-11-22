const std = @import("std");
const dnd_tournament_npcs = @import("dnd_tournament_npcs");
const NPC = @import("my_types.zig").NPC;
const ops = @import("operations.zig");
const print = std.debug.print;

pub fn main() !void {
    var npcs = [31]NPC{
        .{ .id = 0, .name = "Frodo", .max_hp = 36, .hp = 36, .party_id = 0, .zone_id = 3 },
        .{ .id = 1, .name = "Sam", .max_hp = 52, .hp = 52, .party_id = 0, .zone_id = 3 },
        .{ .id = 2, .name = "Legolas", .max_hp = 39, .hp = 39, .party_id = 0, .zone_id = 3 },
        .{ .id = 3, .name = "Aragorn", .max_hp = 65, .hp = 65, .party_id = 0, .zone_id = 3 },
        .{ .id = 4, .name = "Gimli", .max_hp = 60, .hp = 60, .party_id = 0, .zone_id = 3 },

        .{ .id = 5, .name = "Harry", .max_hp = 81, .hp = 81, .party_id = 1, .zone_id = 2 },
        .{ .id = 6, .name = "Ron", .max_hp = 49, .hp = 49, .party_id = 1, .zone_id = 2 },
        .{ .id = 7, .name = "Hermione", .max_hp = 75, .hp = 75, .party_id = 1, .zone_id = 2 },
        .{ .id = 8, .name = "Hagrid", .max_hp = 52, .hp = 52, .party_id = 1, .zone_id = 2 },

        .{ .id = 9, .name = "Khaleesi", .max_hp = 44, .hp = 44, .party_id = 2, .zone_id = 4 },
        .{ .id = 10, .name = "Drogon", .max_hp = 110, .hp = 110, .party_id = 2, .zone_id = 4 },
        .{ .id = 11, .name = "Jon", .max_hp = 65, .hp = 65, .party_id = 2, .zone_id = 4 },
        .{ .id = 12, .name = "Aria", .max_hp = 55, .hp = 55, .party_id = 2, .zone_id = 4 },

        .{ .id = 13, .name = "Geralt", .max_hp = 112, .hp = 112, .party_id = 3, .zone_id = 2 },
        .{ .id = 14, .name = "Jennefer", .max_hp = 81, .hp = 81, .party_id = 3, .zone_id = 2 },
        .{ .id = 15, .name = "Jaskier", .max_hp = 27, .hp = 27, .party_id = 3, .zone_id = 2 },
        .{ .id = 16, .name = "Ciri", .max_hp = 88, .hp = 88, .party_id = 3, .zone_id = 2 },

        .{ .id = 17, .name = "Link", .max_hp = 112, .hp = 112, .party_id = 4, .zone_id = 3 },
        .{ .id = 18, .name = "Zelda", .max_hp = 49, .hp = 49, .party_id = 4, .zone_id = 3 },
        .{ .id = 19, .name = "Mario", .max_hp = 52, .hp = 52, .party_id = 4, .zone_id = 3 },
        .{ .id = 20, .name = "Luigi", .max_hp = 52, .hp = 52, .party_id = 4, .zone_id = 3 },

        .{ .id = 21, .name = "Shadowheart", .max_hp = 44, .hp = 44, .party_id = 5, .zone_id = 1 },
        .{ .id = 22, .name = "Karlach", .max_hp = 67, .hp = 67, .party_id = 5, .zone_id = 1 },
        .{ .id = 23, .name = "Laezel", .max_hp = 60, .hp = 60, .party_id = 5, .zone_id = 1 },
        .{ .id = 24, .name = "Astarion", .max_hp = 55, .hp = 55, .party_id = 5, .zone_id = 1 },
        .{ .id = 25, .name = "Gale", .max_hp = 49, .hp = 49, .party_id = 5, .zone_id = 1 },

        .{ .id = 26, .name = "Groot", .max_hp = 102, .hp = 102, .party_id = 6, .zone_id = 1 },
        .{ .id = 27, .name = "Rocket", .max_hp = 36, .hp = 36, .party_id = 6, .zone_id = 1 },
        .{ .id = 28, .name = "Peter", .max_hp = 39, .hp = 39, .party_id = 6, .zone_id = 1 },
        .{ .id = 29, .name = "Drax", .max_hp = 71, .hp = 71, .party_id = 6, .zone_id = 1 },
        .{ .id = 30, .name = "Gamorra", .max_hp = 42, .hp = 42, .party_id = 6, .zone_id = 1 },
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
            } else if (std.mem.eql(u8, token, "m")) {
                if (it.next()) |id_str| {
                    if (it.next()) |z_str| {
                        const id = try std.fmt.parseUnsigned(u8, id_str, 10);
                        const z = try std.fmt.parseUnsigned(u8, z_str, 10);
                        const npc = ops.getNPC(id, npcs[0..]);
                        if (npc) |unw| {
                            try ops.changeZone(unw, z, zones[0..], allocator);
                        }
                        try ops.printZones(test_zones[0..], zones[0..]);
                    } else {
                        print("missing zone id!\n", .{});
                    }
                } else {
                    print("m needs a character id!\n", .{});
                }
            } else if (std.mem.eql(u8, token, "g")) {
                if (it.next()) |val| {
                    if (val.len == 4) {
                        const zs = try ops.parseZones(val);
                        try ops.mergeZones(zs, zones[0..], allocator);
                        try ops.printZones(test_zones[0..], zones[0..]);
                        rounds += 1;
                    } else {
                        print("Needs 4 zones! {s} \n", .{val});
                    }
                } else {
                    print("g needs a value! try 1100\n", .{});
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
