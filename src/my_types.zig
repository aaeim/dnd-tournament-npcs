const std = @import("std");

pub const NPC = struct {
    id: u8,
    name: []const u8,
    max_hp: u16,
    hp: u16,
    party_id: u8,
    zone_id: u8,

    pub fn status(self: NPC, buf: []u8) ![]u8 {
        return try std.fmt.bufPrint(buf, "{}-{s}: {}", .{ self.id, self.name, self.hp });
    }
};
