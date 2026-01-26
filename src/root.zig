const std = @import("std");
const windows = @import("std").os.windows;

const ScriptHookZig = @import("ScriptHookZig");
const Hook = ScriptHookZig.Hook;

const script = @import("script.zig");

pub const std_options: std.Options = .{
    .log_level = std.log.Level.debug,
};

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

    // Increase the console buffer size to allow more scrollback.
    _ = SetConsoleScreenBufferSize(
        windows.GetStdHandle(windows.STD_OUTPUT_HANDLE) catch return,
        windows.COORD{ .X = 80, .Y = 2560 },
    );
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
            Hook.scriptRegister(@ptrCast(hinstDLL), script.scriptMain) catch |err| {
                std.debug.print("Failed to register script due to error: {t}\n", .{err});
                return windows.FALSE;
            };
        },
        .PROCESS_DETACH => {
            Hook.scriptUnregister(@ptrCast(hinstDLL)) catch |err| {
                std.debug.print("Failed to unregister script due to error: {t}\n", .{err});
                return windows.FALSE;
            };
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

pub extern "kernel32" fn SetConsoleScreenBufferSize(
    hConsoleOutput: windows.HANDLE,
    dwSize: windows.COORD,
) callconv(.winapi) windows.BOOL;

pub extern "user32" fn MessageBoxA(
    hWnd: ?windows.HWND,
    lpText: ?windows.LPCSTR,
    lpCaption: ?windows.LPCSTR,
    uType: packed struct(windows.UINT) {
        /// Bits 0-3: Button type
        button_type: enum(u4) {
            /// MB_OK
            ok = 0x0,
            /// MB_OKCANCEL
            ok_cancel = 0x1,
            /// MB_ABORTRETRYIGNORE
            abort_retry_ignore = 0x2,
            /// MB_YESNOCANCEL
            yes_no_cancel = 0x3,
            /// MB_YESNO
            yes_no = 0x4,
            /// MB_RETRYCANCEL
            retry_cancel = 0x5,
            /// MB_CANCELTRYCONTINUE
            cancel_try_continue = 0x6,
            _,
        } = .ok,

        /// Bits 4-7: Icon type
        icon_type: enum(u4) {
            none = 0x0,
            /// MB_ICONSTOP / MB_ICONERROR / MB_ICONHAND (0x10)
            stop = 0x1,
            /// MB_ICONQUESTION (0x20)
            question = 0x2,
            /// MB_ICONEXCLAMATION / MB_ICONWARNING (0x30)
            exclamation = 0x3,
            /// MB_ICONINFORMATION / MB_ICONASTERISK (0x40)
            information = 0x4,
            _,
        } = .none,

        /// Bits 8-11: Default button
        default_button: enum(u4) {
            /// MB_DEFBUTTON1
            button1 = 0x0,
            /// MB_DEFBUTTON2
            button2 = 0x1,
            /// MB_DEFBUTTON3
            button3 = 0x2,
            /// MB_DEFBUTTON4
            button4 = 0x3,
            _,
        } = .button1,

        /// Bits 12-13: Modality
        modality: enum(u2) {
            /// MB_APPLMODAL
            application = 0x0,
            /// MB_SYSTEMMODAL
            system = 0x1,
            /// MB_TASKMODAL
            task = 0x2,
            _,
        } = .application,

        /// Bit 14: MB_HELP (0x4000)
        help: bool = false,

        /// Bit 15: Reserved
        _reserved1: u1 = 0,

        /// Bit 16: MB_SETFOREGROUND (0x10000)
        set_foreground: bool = false,

        /// Bit 17: MB_DEFAULT_DESKTOP_ONLY (0x20000)
        default_desktop_only: bool = false,

        /// Bit 18: MB_TOPMOST (0x40000)
        topmost: bool = false,

        /// Bit 19: MB_RIGHT (0x80000)
        right: bool = false,

        /// Bit 20: MB_RTLREADING (0x100000)
        rtl_reading: bool = false,

        /// Bit 21: MB_SERVICE_NOTIFICATION (0x200000)
        service_notification: bool = false,

        /// Bits 22-31: Reserved
        _reserved2: u10 = 0,

        /// Convert to raw UINT value for Windows API
        pub fn toUint(self: @This()) windows.UINT {
            return @bitCast(self);
        }

        /// Create from raw UINT value
        pub fn fromUint(value: windows.UINT) @This() {
            return @bitCast(value);
        }
    },
) callconv(.winapi) c_int;

test "root" {
    const testing = std.testing;

    testing.refAllDeclsRecursive(@This());
}
