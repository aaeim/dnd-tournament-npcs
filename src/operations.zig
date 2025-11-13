const NPC = @import("my_types.zig").NPC;
const std = @import("std");
const print = std.debug.print;

//pub fn printNPCs(npcs: []NPC) void {}

pub fn getNewZone(current: u8) u8 {
    return switch (current) {
        1 => 3,
        2 => 4,
        3 => 2,
        4 => 1,
        else => current,
    };
}

pub fn printNPCs(npcs: []NPC) !void {
    var str_buffer: [32]u8 = undefined;
    for (npcs) |npc| {
        const str = try npc.status(&str_buffer);
        print("{s}\n", .{str});
    }
}

pub fn updateZones(npcs: []NPC, zones: []std.ArrayList(*NPC), allocator: std.mem.Allocator) !void {
    for (zones) |*z| {
        z.clearRetainingCapacity();
    }
    for (npcs) |*npc| {
        try zones[npc.zone_id - 1].append(allocator, npc);
    }
}

pub fn printZones(ids: []const u8, zones: []std.ArrayList(*NPC)) !void {
    for (ids) |id| {
        const idx: u8 = id - 1;
        if (idx >= zones.len) continue;
        try printZone(id, &zones[idx]);
    }
    print("\n===============================\n", .{});
}

pub fn printZone(id: u8, z: *std.ArrayList(*NPC)) !void {
    print("\nZone {}\n", .{id});

    var str_buffer: [32]u8 = undefined;

    for (z.items) |npc| {
        const str = try npc.status(&str_buffer);
        print("{s}\n", .{str});
    }
}

pub fn changeZone(npc: *NPC, new_zone: u8, zones: []std.ArrayList(*NPC), allocator: std.mem.Allocator) !void {
    const idx: u8 = getIndex(npc, &zones[npc.zone_id - 1]);
    _ = zones[npc.zone_id - 1].swapRemove(idx);
    try zones[new_zone - 1].append(allocator, npc);
    npc.zone_id = new_zone;
}

pub fn getIndex(npc: *NPC, z: *std.ArrayList(*NPC)) u8 {
    for (0..z.items.len) |i| {
        if (z.items[i].id == npc.id) return @intCast(i);
    }
    return 0; // prob should return error or something
}

fn getEnemySum(id: u8, units: []u8) u8 {
    var sum: u8 = 0;
    for (0..7) |i| {
        if (i == id) continue;
        sum += units[i];
    }
    return sum;
}

pub fn rollAndUpdate(active_zones: [4]u8, npcs: []NPC, zones: []std.ArrayList(*NPC), allocator: std.mem.Allocator, dice: std.Random) !void {
    var z1_units: [7]u8 = .{0} ** 7;
    var z2_units: [7]u8 = .{0} ** 7;
    var z3_units: [7]u8 = .{0} ** 7;
    var z4_units: [7]u8 = .{0} ** 7;

    for (npcs) |npc| {
        if (npc.hp == 0) continue;
        switch (npc.zone_id) {
            1 => z1_units[npc.party_id] += 1,
            2 => z2_units[npc.party_id] += 1,
            3 => z3_units[npc.party_id] += 1,
            4 => z4_units[npc.party_id] += 1,
            else => {},
        }
    }

    for (npcs) |*npc| {
        if (active_zones[npc.zone_id - 1] == 0) continue;
        if (npc.hp == 0) continue;

        var enemies: u8 = 0;
        switch (npc.zone_id) {
            1 => enemies = getEnemySum(npc.party_id, z1_units[0..]),
            2 => enemies = getEnemySum(npc.party_id, z2_units[0..]),
            3 => enemies = getEnemySum(npc.party_id, z3_units[0..]),
            4 => enemies = getEnemySum(npc.party_id, z4_units[0..]),
            else => {},
        }

        const roll: u8 = dice.intRangeLessThan(u8, 1, 21);
        switch (roll) {
            1 => {
                const nz = getNewZone(npc.zone_id);
                try changeZone(npc, nz, zones[0..], allocator);
                npc.hp -|= enemies * 3;
            },
            2...9 => {
                npc.hp -|= enemies * 3;
            },
            10...19 => {
                npc.hp -|= enemies * 2;
            },
            else => {},
        }
    }
}

pub fn parseZones(z_str: []const u8) ![4]u8 {
    var zones: [4]u8 = undefined;
    for (0..4) |i| {
        zones[i] = try std.fmt.parseInt(u8, z_str[i .. i + 1], 10);
    }
    return zones;
}

pub fn getNPC(id: u8, npcs: []NPC) ?*NPC {
    for (npcs) |*npc| {
        if (npc.id == id) return npc;
    }
    return null;
}
