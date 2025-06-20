const windows = @import("std").os.windows;

// Textures

/// **Create texture**
///
/// **Arguments**:
///   - **texFileName**
///     - texture file name, it's best to specify full texture path and use PNG textures
///
/// **Returns**:
///   - internal texture id
///
/// Texture deletion is performed automatically when game reloads scripts
///
/// Can be called only in the same thread as natives
pub fn createTexture(texFileName: [*:0]const u8) callconv(.c) c_int {
    const func = @extern(
        *const @TypeOf(createTexture),
        .{
            .name = "?createTexture@@YAHPEBD@Z",
            .is_dll_import = true,
        },
    );

    return func(texFileName);
}

/// **Draw texture**
///
/// **Arguments**:
///   - id
///     - texture id recieved from createTexture()
///   - index
///     - each texture can have up to 64 different instances on screen at one time
///   - level
///     - draw level, being used in global draw order, texture instance with least level draws first
///   - time
///     - how much time (ms) texture instance will stay on screen, the amount of time should be enough
///         for it to stay on screen until the next corresponding drawTexture() call
///   - sizeX,Y
///     - size in screen space, should be in the range from 0.0 to 1.0, e.g setting this to 0.2 means that
///         texture instance will take 20% of the screen space
///   - centerX,Y
///     - center position in texture space, e.g. 0.5 means real texture center
///   - posX,Y
///     - position in screen space, [0.0, 0.0] - top left corner, [1.0, 1.0] - bottom right,
///         texture instance is positioned according to it's center
///   - rotation
///     - should be in the range from 0.0 to 1.0
///   - screenHeightScaleFactor
///     - screen aspect ratio, used for texture size correction, you can get it using natives
///   - r,g,b,a
///     - color, should be in the range from 0.0 to 1.0
///
///  Texture instance draw parameters are updated each time script performs corresponding call to drawTexture()
///
///  You should always check your textures layout for 16:9, 16:10 and 4:3 screen aspects, for ex. in 1280x720,
///  1440x900 and 1024x768 screen resolutions, use windowed mode for this
///
///  Can be called only in the same thread as natives
pub fn drawTexture(
    id: c_int,
    index: c_int,
    level: c_int,
    time: c_int,
    sizeX: f32,
    sizeY: f32,
    centerX: f32,
    centerY: f32,
    posX: f32,
    posY: f32,
    rotation: f32,
    screenHeightScaleFactor: f32,
    r: f32,
    g: f32,
    b: f32,
    a: f32,
) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(drawTexture),
        .{
            .name = "?drawTexture@@YAXHHHHMMMMMMMMMMMM@Z",
            .is_dll_import = true,
        },
    );

    func(
        id,
        index,
        level,
        time,
        sizeX,
        sizeY,
        centerX,
        centerY,
        posX,
        posY,
        rotation,
        screenHeightScaleFactor,
        r,
        g,
        b,
        a,
    );
}

/// **IDXGISwapChain::Present callback**
///
/// Called right before the actual Present method call, render test calls don't trigger callbacks
///
/// When the game uses DX10 it actually uses DX11 with DX10 feature level
///
/// Remember that you can't call natives inside
/// `void OnPresent(IDXGISwapChain *swapChain);`
pub const PresentCallback = ?*const fn (?*anyopaque) callconv(.c) void;

/// **Register IDXGISwapChain::Present callback**
///
/// must be called on dll attach
pub fn presentCallbackRegister(cb: PresentCallback) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(presentCallbackRegister),
        .{
            .name = "?presentCallbackRegister@@YAXP6AXPEAX@Z@Z",
            .is_dll_import = true,
        },
    );

    func(cb);
}

/// **Unregister IDXGISwapChain::Present callback**
///
/// must be called on dll detach
pub fn presentCallbackUnregister(cb: PresentCallback) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(presentCallbackUnregister),
        .{
            .name = "?presentCallbackUnregister@@YAXP6AXPEAX@Z@Z",
            .is_dll_import = true,
        },
    );

    func(cb);
}

// Keyboard

pub const KeyboardHandler = ?*const fn (
    key: windows.DWORD,
    repeats: windows.WORD,
    scanCode: windows.BYTE,
    isExtended: windows.BOOL,
    isWithAlt: windows.BOOL,
    wasDownBefore: windows.BOOL,
    isUpNow: windows.BOOL,
) callconv(.c) void;

/// **Register keyboard handler**
///
/// must be called on dll attach
pub fn keyboardHandlerRegister(handler: KeyboardHandler) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(keyboardHandlerRegister),
        .{
            .name = "?keyboardHandlerRegister@@YAXP6AXKGEHHHH@Z@Z",
            .is_dll_import = true,
        },
    );

    func(handler);
}

/// **Unregister keyboard handler**
///
/// must be called on dll detach
pub fn keyboardHandlerUnregister(handler: KeyboardHandler) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(keyboardHandlerUnregister),
        .{
            .name = "?keyboardHandlerUnregister@@YAXP6AXKGEHHHH@Z@Z",
            .is_dll_import = true,
        },
    );

    func(handler);
}

// Scripts

pub fn scriptWait(time: windows.DWORD) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(scriptWait),
        .{
            .name = "?scriptWait@@YAXK@Z",
            .is_dll_import = true,
        },
    );

    func(time);
}

pub fn scriptRegister(module: windows.HMODULE, LP_SCRIPT_MAIN: ?*const fn () callconv(.c) void) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(scriptRegister),
        .{
            .name = "?scriptRegister@@YAXPEAUHINSTANCE__@@P6AXXZ@Z",
            .is_dll_import = true,
        },
    );

    func(module, LP_SCRIPT_MAIN);
}

pub fn scriptRegisterAdditionalThread(module: windows.HMODULE, LP_SCRIPT_MAIN: ?*const fn () callconv(.c) void) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(scriptRegisterAdditionalThread),
        .{
            .name = "?scriptRegisterAdditionalThread@@YAXPEAUHINSTANCE__@@P6AXXZ@Z",
            .is_dll_import = true,
        },
    );

    func(module, LP_SCRIPT_MAIN);
}

pub fn scriptUnregister(module: windows.HMODULE) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(scriptUnregister),
        .{
            .name = "?scriptUnregister@@YAXPEAUHINSTANCE__@@@Z",
            .is_dll_import = true,
        },
    );

    func(module);
}

/// deprecated
pub fn _scriptUnregister(LP_SCRIPT_MAIN: ?*const fn () callconv(.c) void) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(_scriptUnregister),
        .{
            .name = "?scriptUnregister@@YAXP6AXXZ@Zv",
            .is_dll_import = true,
        },
    );

    func(LP_SCRIPT_MAIN);
}

pub fn nativeInit(hash: u64) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(nativeInit),
        .{
            .name = "?nativeInit@@YAX_K@Z",
            .is_dll_import = true,
        },
    );

    func(hash);
}

pub fn nativePush64(val: u64) callconv(.c) void {
    const func = @extern(
        *const @TypeOf(nativePush64),
        .{
            .name = "?nativePush64@@YAX_K@Z",
            .is_dll_import = true,
        },
    );

    func(val);
}

pub fn nativeCall() callconv(.c) *u64 {
    const func = @extern(
        *const @TypeOf(nativeCall),
        .{
            .name = "?nativeCall@@YAPEA_KXZ",
            .is_dll_import = true,
        },
    );

    return func();
}

pub fn wait(time: windows.DWORD) callconv(.c) void {
    scriptWait(time);
}

pub fn terminate() callconv(.c) void {
    wait(0xFFFFFFFF);
}

/// Returns pointer to global variable
/// make sure that you check game version before accessing globals because
/// ids may differ between patches
pub fn getGlobalPtr(globalId: c_int) callconv(.c) *u64 {
    const func = @extern(
        *const @TypeOf(getGlobalPtr),
        .{
            .name = "?getGlobalPtr@@YAPEA_KH@Z",
            .is_dll_import = true,
        },
    );

    return func(globalId);
}

// World

/// Get entities from internal pools
/// return value represents filled array elements count
/// can be called only in the same thread as natives
pub fn worldGetAllVehicles(arr: [*]c_int, arrSize: c_int) callconv(.c) c_int {
    const func = @extern(
        *const @TypeOf(worldGetAllVehicles),
        .{
            .name = "?worldGetAllVehicles@@YAHPEAHH@Z",
            .is_dll_import = true,
        },
    );

    return func(arr, arrSize);
}

pub fn worldGetAllPeds(arr: [*]c_int, arrSize: c_int) callconv(.c) c_int {
    const func = @extern(
        *const @TypeOf(worldGetAllPeds),
        .{
            .name = "?worldGetAllPeds@@YAHPEAHH@Z",
            .is_dll_import = true,
        },
    );

    return func(arr, arrSize);
}

pub fn worldGetAllObjects(arr: [*]c_int, arrSize: c_int) callconv(.c) c_int {
    const func = @extern(
        *const @TypeOf(worldGetAllObjects),
        .{
            .name = "?worldGetAllObjects@@YAHPEAHH@Z",
            .is_dll_import = true,
        },
    );

    return func(arr, arrSize);
}

pub fn worldGetAllPickups(arr: [*]c_int, arrSize: c_int) callconv(.c) c_int {
    const func = @extern(
        *const @TypeOf(worldGetAllPickups),
        .{
            .name = "?worldGetAllPickups@@YAHPEAHH@Z",
            .is_dll_import = true,
        },
    );

    return func(arr, arrSize);
}

// Misc

/// Returns base object pointer using it's script handle
/// make sure that you check game version before accessing object fields because
/// offsets may differ between patches
pub fn getScriptHandleBaseAddress(handle: c_int) callconv(.c) [*c]windows.BYTE {
    const func = @extern(
        *const @TypeOf(getScriptHandleBaseAddress),
        .{
            .name = "?getScriptHandleBaseAddress@@YAPEAEH@Z",
            .is_dll_import = true,
        },
    );

    return func(handle);
}

pub const eGameVersion = enum(c_int) {
    VER_1_0_335_2_NOSTEAM,
    VER_1_0_350_1_STEAM,
    VER_1_0_350_2_NOSTEAM,
    VER_1_0_372_2_STEAM,
    VER_1_0_372_2_NOSTEAM,
    VER_1_0_393_2_STEAM,
    VER_1_0_393_2_NOSTEAM,
    VER_1_0_393_4_STEAM,
    VER_1_0_393_4_NOSTEAM,
    VER_1_0_463_1_STEAM,
    VER_1_0_463_1_NOSTEAM,
    VER_1_0_505_2_STEAM,
    VER_1_0_505_2_NOSTEAM,
    VER_1_0_573_1_STEAM,
    VER_1_0_573_1_NOSTEAM,
    VER_1_0_617_1_STEAM,
    VER_1_0_617_1_NOSTEAM,
    VER_1_0_678_1_STEAM,
    VER_1_0_678_1_NOSTEAM,
    VER_1_0_757_2_STEAM,
    VER_1_0_757_2_NOSTEAM,
    VER_1_0_757_4_STEAM,
    VER_1_0_757_4_NOSTEAM,
    VER_1_0_791_2_STEAM,
    VER_1_0_791_2_NOSTEAM,
    VER_1_0_877_1_STEAM,
    VER_1_0_877_1_NOSTEAM,
    VER_1_0_944_2_STEAM,
    VER_1_0_944_2_NOSTEAM,
    VER_1_0_1011_1_STEAM,
    VER_1_0_1011_1_NOSTEAM,
    VER_1_0_1032_1_STEAM,
    VER_1_0_1032_1_NOSTEAM,
    VER_1_0_1103_2_STEAM,
    VER_1_0_1103_2_NOSTEAM,
    VER_1_0_1180_2_STEAM,
    VER_1_0_1180_2_NOSTEAM,
    VER_1_0_1290_1_STEAM,
    VER_1_0_1290_1_NOSTEAM,
    VER_1_0_1365_1_STEAM,
    VER_1_0_1365_1_NOSTEAM,
    VER_1_0_1493_0_STEAM,
    VER_1_0_1493_0_NOSTEAM,
    VER_1_0_1493_1_STEAM,
    VER_1_0_1493_1_NOSTEAM,
    VER_1_0_1604_0_STEAM,
    VER_1_0_1604_0_NOSTEAM,
    VER_1_0_1604_1_STEAM,
    VER_1_0_1604_1_NOSTEAM,
    VER_1_0_1737_0_STEAM,
    VER_1_0_1737_0_NOSTEAM,
    VER_1_0_1737_6_STEAM,
    VER_1_0_1737_6_NOSTEAM,
    VER_1_0_1868_0_STEAM,
    VER_1_0_1868_0_NOSTEAM,
    VER_1_0_1868_1_STEAM,
    VER_1_0_1868_1_NOSTEAM,
    VER_1_0_1868_4_EGS,
    VER_1_0_2060_0_STEAM,
    VER_1_0_2060_0_NOSTEAM,
    VER_1_0_2060_1_STEAM,
    VER_1_0_2060_1_NOSTEAM,
    VER_1_0_2189_0_STEAM,
    VER_1_0_2189_0_NOSTEAM,
    VER_1_0_2215_0_STEAM,
    VER_1_0_2215_0_NOSTEAM,
    VER_1_0_2245_0_STEAM,
    VER_1_0_2245_0_NOSTEAM,
    VER_1_0_2372_0_STEAM,
    VER_1_0_2372_0_NOSTEAM,
    VER_1_0_2545_0_STEAM,
    VER_1_0_2545_0_NOSTEAM,
    VER_1_0_2612_1_STEAM,
    VER_1_0_2612_1_NOSTEAM,
    VER_1_0_2628_2_STEAM,
    VER_1_0_2628_2_NOSTEAM,
    VER_1_0_2699_0_STEAM,
    VER_1_0_2699_0_NOSTEAM,
    VER_1_0_2699_16,
    VER_1_0_2802_0,
    VER_1_0_2824_0,
    VER_1_0_2845_0,
    VER_1_0_2944_0,
    VER_1_0_3028_0,
    VER_1_0_3095_0,
    VER_1_0_3179_0,
    VER_1_0_3258_0,
    VER_1_0_3274_0,
    VER_1_0_3323_0,
    VER_1_0_3337_0,
    VER_1_0_3351_0,
    VER_1_0_3407_0,
    VER_1_0_3411_0,
    VER_1_0_3442_0,
    VER_1_0_3504_0,
    VER_1_0_3521_0,
    VER_1_0_3570_0,

    VER_EN_1_0_811_8 = 1001,
    VER_EN_1_0_812_8,
    VER_EN_1_0_813_11,
    VER_EN_1_0_814_9,
    VER_EN_1_0_889_15,
    _,
};

pub fn getGameVersion() callconv(.c) eGameVersion {
    const func = @extern(
        *const @TypeOf(getGameVersion),
        .{
            .name = "?getGameVersion@@YA?AW4eGameVersion@@XZ",
            .is_dll_import = true,
        },
    );

    return func();
}
