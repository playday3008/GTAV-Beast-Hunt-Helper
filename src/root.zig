const std = @import("std");
const windows = @import("std").os.windows;

const ScriptHookZig = @import("ScriptHookZig");
const Hook = ScriptHookZig.Hook;

const script = @import("script.zig");

var console_thread: ?std.Thread = null;

/// Tries to attach to an existing console, or allocates a new one.
/// Runs in separate thread to avoid blocking the main thread.
fn allocConsole() void {
    // Try to attach to an existing console.
    while (AttachConsole(windows.GetCurrentProcessId()) == 0) {
        // If handle is invalid, there is no console to attach to.
        if (windows.GetLastError() != windows.Win32Error.INVALID_HANDLE) {
            break;
        }

        // Attach failed because there is no console, so allocate a new one.
        _ = AllocConsole();
    }
}

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
            console_thread = std.Thread.spawn(.{}, allocConsole, .{}) catch null;
            Hook.scriptRegister(@ptrCast(hinstDLL), script.scriptMain);
        },
        .PROCESS_DETACH => {
            Hook.scriptUnregister(@ptrCast(hinstDLL));
            if (console_thread) |thread| {
                _ = FreeConsole();
                thread.join();
            }
        },
        else => {},
    }

    return windows.TRUE;
}

pub extern "kernel32" fn AllocConsole() callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn AttachConsole(dwProcessId: windows.DWORD) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn FreeConsole() callconv(.winapi) windows.BOOL;

test "root" {
    const testing = std.testing;

    testing.refAllDeclsRecursive(@This());
}
