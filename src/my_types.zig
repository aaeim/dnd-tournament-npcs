const std = @import("std");

pub const NPC = struct {
    id: u8,
    name: []const u8,
    hp: u16,
    party_id: u8,
    zone_id: u8,

    pub fn status(self: NPC, buf: []u8) ![]u8 {
        return try std.fmt.bufPrint(buf, "{s}: {}", .{ self.name, self.hp });
    }
};
