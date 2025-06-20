const ScriptHookV = @import("ScriptHookV.zig");

pub inline fn nativePush(comptime T: type, val: T) void {
    var val64: u64 = 0;
    if (@sizeOf(T) > @sizeOf(u64)) {
        @compileError("type " ++ @typeName(T) ++ " is too large to be passed as a native argument");
    }
    @as(*T, @ptrCast(@alignCast(&val64))).* = val;
    ScriptHookV.nativePush64(val64);
}

pub inline fn invoke(comptime R: type, hash: u64, args: anytype) R {
    ScriptHookV.nativeInit(hash);

    const ArgsType = @TypeOf(args);
    const args_type_info = @typeInfo(ArgsType);
    if (args_type_info != .@"struct") {
        @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));
    }
    const fields_info = args_type_info.@"struct".fields;
    if (fields_info.len > 25) {
        @compileError("too many arguments, maximum is 25, found " ++ (fields_info.len));
    }

    inline for (fields_info) |field_info| {
        const field_name = field_info.name;
        const field = @field(args, field_name);
        nativePush(@TypeOf(field), field);
    }

    return @as(*R, @ptrCast(@alignCast(ScriptHookV.nativeCall()))).*;
}
