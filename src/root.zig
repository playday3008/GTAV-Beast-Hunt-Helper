const std = @import("std");
const windows = @import("std").os.windows;

const ScriptHookZig = @import("ScriptHookZig");
const Hook = ScriptHookZig.Hook;

const script = @import("script.zig");

pub var arena: std.heap.ArenaAllocator = undefined;

pub fn DllMain(
    hinstDLL: windows.HINSTANCE,
    fdwReason: windows.DWORD,
    _: windows.LPVOID,
) windows.BOOL {
    const reason: enum(windows.DWORD) {
        PROCESS_ATTACH = 1,
        PROCESS_DETACH = 0,
        THREAD_ATTACH = 2,
        THREAD_DETACH = 3,
        _,
    } = @enumFromInt(fdwReason);

    switch (reason) {
        .PROCESS_ATTACH => {
            arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            //_ = AllocConsole();
            Hook.scriptRegister(@ptrCast(hinstDLL), script.scriptMain);
        },
        .PROCESS_DETACH => {
            Hook.scriptUnregister(@ptrCast(hinstDLL));
            //_ = FreeConsole();
            arena.deinit();
        },
        else => {},
    }

    return windows.TRUE;
}

pub extern "kernel32" fn AttachConsole(
    dwProcessId: windows.DWORD,
) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn AllocConsole() callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn FreeConsole() callconv(.winapi) windows.BOOL;

test "root" {
    const testing = std.testing;

    testing.refAllDeclsRecursive(@This());
}
