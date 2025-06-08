const std = @import("std");
const windows = std.os.windows;

pub const Void = windows.DWORD;
pub const Any = windows.DWORD;
pub const uint = windows.DWORD;
pub const Hash = windows.DWORD;

pub const Blip = c_int;
pub const Cam = c_int;
pub const Camera = c_int;
pub const CarGenerator = c_int;
pub const ColourIndex = c_int;
pub const CoverPoint = c_int;
pub const Entity = c_int;
pub const FireId = c_int;
pub const Group = c_int;
pub const Interior = c_int;
pub const Object = c_int;
pub const Ped = c_int;
pub const Pickup = c_int;
pub const Player = c_int;
pub const ScrHandle = c_int;
pub const Sphere = c_int;
pub const TaskSequence = c_int;
pub const Texture = c_int;
pub const TextureDict = c_int;
pub const Train = c_int;
pub const Vehicle = c_int;
pub const Weapon = c_int;

pub const Vector2_ = extern struct {
    x: f32,
    _x: u32, // Padding
    y: f32,
    _y: u32, // Padding

    comptime {
        const expected_size = 2 * @sizeOf(u64);
        if (@sizeOf(@This()) != expected_size) {
            @compileError(std.fmt.comptimePrint(
                "Size of {s} isn't 0x{X}, it's 0x{X}",
                .{
                    @typeName(@This()),
                    expected_size,
                    @sizeOf(@This()),
                },
            ));
        }
    }
};
pub const Vector3 = extern struct {
    x: f32,
    _x: u32, // Padding
    y: f32,
    _y: u32, // Padding
    z: f32,
    _z: u32, // Padding

    comptime {
        const expected_size = 3 * @sizeOf(u64);
        if (@sizeOf(@This()) != expected_size) {
            @compileError(std.fmt.comptimePrint(
                "Size of {s} isn't 0x{X}, it's 0x{X}",
                .{
                    @typeName(@This()),
                    expected_size,
                    @sizeOf(@This()),
                },
            ));
        }
    }
};
pub const Vector4 = extern struct {
    x: f32,
    _x: u32, // Padding
    y: f32,
    _y: u32, // Padding
    z: f32,
    _z: u32, // Padding
    w: f32,
    _w: u32, // Padding

    comptime {
        const expected_size = 4 * @sizeOf(u64);
        if (@sizeOf(@This()) != expected_size) {
            @compileError(std.fmt.comptimePrint(
                "Size of {s} isn't 0x{X}, it's 0x{X}",
                .{
                    @typeName(@This()),
                    expected_size,
                    @sizeOf(@This()),
                },
            ));
        }
    }
};
