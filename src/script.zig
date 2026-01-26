const std = @import("std");
const w = std.os.windows;

const log = std.log.scoped(.script);

const ScriptHookZig = @import("ScriptHookZig");
const Hook = ScriptHookZig.Hook;
const Types = ScriptHookZig.Types;
const Joaat = ScriptHookZig.Joaat;
const Natives = @import("natives.zig");

const root = @import("root");

// Constants
const CHECKPOINT_COUNT = 11;
const MAX_PATH_COUNT = 64;
const NODES_PER_PATH = 4;
const PATH_NODE_RADIUS = 17.0;

var g_offset: struct {
    iSPInitBitset: c_int,
    vBHCheckpoints: c_int,
    iBHPathIndexes: c_int,
    sBHPath: c_int,
} = undefined;

var g: struct {
    iSPInitBitset: *packed struct(u64) {
        INSTALL_SCREEN_FINISHED: bool,
        TITLE_SEQUENCE_DISPLAYED: bool,
        TURN_ON_LOST_BIKER_GROUP: bool,
        RESTORE_SLEEP_MODE: bool,
        LOADED_DIRECTLY_INTO_MISSION: bool,
        UNLOCK_SHINE_A_LIGHT: bool,
        SHRINK_SESSION_ATTENDED: bool,
        BEAST_PEYOTES_COLLECTED: bool,
        BEAST_HUNT_COMPLETED: bool,
        BEAST_FIGHT_FAILED: bool,
        BEAST_KILLED_AND_UNLOCKED: bool,
        BEAST_LAST_PEYOTE_DAY: u3,
        BEAST_CURRENT_CHECKPOINT: u4,
        BEAST_NEXT_CHECKPOINT: u4,
        BEAST_CALL_MADE: bool,
        _: u41, // Padding

        comptime {
            const expected_size = @bitSizeOf(u64);
            if (@bitSizeOf(@This()) != expected_size) {
                @compileError(std.fmt.comptimePrint(
                    "Size of {s} isn't 0x{X}, it's 0x{X} (bit size)",
                    .{
                        @typeName(@This()),
                        expected_size,
                        @bitSizeOf(@This()),
                    },
                ));
            }
        }
    },
    vBHCheckpoints: *extern struct {
        size: u64,
        data: [CHECKPOINT_COUNT]Types.Vector3,

        comptime {
            const expected_size = @sizeOf(u64) + CHECKPOINT_COUNT * 3 * @sizeOf(u64);
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
    },
    iBHPathIndexes: *extern struct {
        size: u64,
        data: [CHECKPOINT_COUNT]extern struct {
            size: u64,
            data: [CHECKPOINT_COUNT]i64,

            comptime {
                const expected_size = @sizeOf(u64) + CHECKPOINT_COUNT * @sizeOf(i64);
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
        },

        comptime {
            const expected_size = @sizeOf(u64) + CHECKPOINT_COUNT * (@sizeOf(u64) + CHECKPOINT_COUNT * @sizeOf(i64));
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
    },
    sBHPath: *extern struct {
        size: u64,
        data: [MAX_PATH_COUNT]extern struct {
            length: u64,
            size: u64,
            nodes: [NODES_PER_PATH]Types.Vector3,

            comptime {
                const expected_size = 2 * @sizeOf(u64) + NODES_PER_PATH * 3 * @sizeOf(u64);
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
        },

        comptime {
            const expected_size = @sizeOf(u64) + MAX_PATH_COUNT * (2 * @sizeOf(u64) + NODES_PER_PATH * 3 * @sizeOf(u64));
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
    },
} = undefined;

pub fn scriptMain() callconv(.c) void {
    log.debug("Script entry point called", .{});
    main() catch |err| {
        log.err("Script terminated due to error: {t}", .{err});
        log.info("Script will now exit", .{});
    };
}

fn main() Hook.Error!void {
    log.debug("Script starting...", .{});

    const gameVersion = Hook.getGameVersionGTAV() catch |err| {
        log.err("Failed to get game version due to: {t}", .{err});
        return;
    };

    log.info("Detected game version: {t}", .{gameVersion});

    g_offset = switch (gameVersion) {
        // Legacy
        // Sources:
        // - https://github.com/calamity-inc/GTA-V-Decompiled-Scripts
        // - https://github.com/root-cause/v-decompiled-scripts
        .VER_1_0_2699_16 => .{
            .iSPInitBitset = 113386 + 10016 + 25,
            .vBHCheckpoints = 110138,
            .iBHPathIndexes = 110138 + 463,
            .sBHPath = 110138 + 463 + 266,
        },
        .VER_1_0_2802_0 => .{
            .iSPInitBitset = 113648 + 10018 + 25,
            .vBHCheckpoints = 110400,
            .iBHPathIndexes = 110400 + 463,
            .sBHPath = 110400 + 463 + 266,
        },
        .VER_1_0_2824_0 => .{
            .iSPInitBitset = 113648 + 10018 + 25,
            .vBHCheckpoints = 110400,
            .iBHPathIndexes = 110400 + 463,
            .sBHPath = 110400 + 463 + 266,
        },
        .VER_1_0_2845_0 => .{
            .iSPInitBitset = 113648 + 10018 + 25,
            .vBHCheckpoints = 110400,
            .iBHPathIndexes = 110400 + 463,
            .sBHPath = 110400 + 463 + 266,
        },
        .VER_1_0_2944_0 => .{
            .iSPInitBitset = 113810 + 10019 + 25,
            .vBHCheckpoints = 110561,
            .iBHPathIndexes = 110561 + 463,
            .sBHPath = 110561 + 463 + 266,
        },
        .VER_1_0_3095_0 => .{
            .iSPInitBitset = 114370 + 10019 + 25,
            .vBHCheckpoints = 111121,
            .iBHPathIndexes = 111121 + 463,
            .sBHPath = 111121 + 463 + 266,
        },
        .VER_1_0_3179_0 => .{
            .iSPInitBitset = 114372 + 10019 + 25,
            .vBHCheckpoints = 111121,
            .iBHPathIndexes = 111121 + 463,
            .sBHPath = 111121 + 463 + 266,
        },
        .VER_1_0_3258_0 => .{
            .iSPInitBitset = 113969 + 10019 + 25,
            .vBHCheckpoints = 110718,
            .iBHPathIndexes = 110718 + 463,
            .sBHPath = 110718 + 463 + 266,
        },
        .VER_1_0_3274_0 => .{
            .iSPInitBitset = 113969 + 10019 + 25,
            .vBHCheckpoints = 110718,
            .iBHPathIndexes = 110718 + 463,
            .sBHPath = 110718 + 463 + 266,
        },
        .VER_1_0_3323_0 => .{
            .iSPInitBitset = 113969 + 10019 + 25,
            .vBHCheckpoints = 110718,
            .iBHPathIndexes = 110718 + 463,
            .sBHPath = 110718 + 463 + 266,
        },
        .VER_1_0_3407_0 => .{
            .iSPInitBitset = 114135 + 10020 + 25,
            .vBHCheckpoints = 110884,
            .iBHPathIndexes = 110884 + 463,
            .sBHPath = 110884 + 463 + 266,
        },
        .VER_1_0_3504_0 => .{
            .iSPInitBitset = 114135 + 10020 + 25,
            .vBHCheckpoints = 110884,
            .iBHPathIndexes = 110884 + 463,
            .sBHPath = 110884 + 463 + 266,
        },
        .VER_1_0_3570_0 => .{
            .iSPInitBitset = 114344 + 10020 + 25,
            .vBHCheckpoints = 111093,
            .iBHPathIndexes = 111093 + 463,
            .sBHPath = 111093 + 463 + 266,
        },
        .VER_1_0_3586_0 => .{
            .iSPInitBitset = 114904 + 10023 + 25,
            .vBHCheckpoints = 111653,
            .iBHPathIndexes = 111653 + 463,
            .sBHPath = 111653 + 463 + 266,
        },
        .VER_1_0_3717_0 => .{
            .iSPInitBitset = 114904 + 10023 + 25,
            .vBHCheckpoints = 111653,
            .iBHPathIndexes = 111653 + 463,
            .sBHPath = 111653 + 463 + 266,
        },
        // Enhanced
        // Source: Me
        .VER_EN_1_0_814_9 => .{
            .iSPInitBitset = 114162 + 10020 + 25,
            .vBHCheckpoints = 110911,
            .iBHPathIndexes = 110911 + 463,
            .sBHPath = 110911 + 463 + 266,
        },
        .VER_EN_1_0_889_15 => .{
            .iSPInitBitset = 114370 + 10020 + 25,
            .vBHCheckpoints = 111119,
            .iBHPathIndexes = 111119 + 463,
            .sBHPath = 111119 + 463 + 266,
        },
        .VER_EN_1_0_889_19 => .{
            .iSPInitBitset = 114370 + 10020 + 25,
            .vBHCheckpoints = 111119,
            .iBHPathIndexes = 111119 + 463,
            .sBHPath = 111119 + 463 + 266,
        },
        .VER_EN_1_0_889_22 => .{
            .iSPInitBitset = 114370 + 10020 + 25,
            .vBHCheckpoints = 111119,
            .iBHPathIndexes = 111119 + 463,
            .sBHPath = 111119 + 463 + 266,
        },
        .VER_EN_1_0_1013_17 => .{
            .iSPInitBitset = 114931 + 10023 + 25,
            .vBHCheckpoints = 111680,
            .iBHPathIndexes = 111680 + 463,
            .sBHPath = 111680 + 463 + 266,
        },
        else => |version| {
            // TODO: Scan globals for known values to auto-detect offsets
            const allocator = std.heap.page_allocator;
            const text = std.fmt.allocPrintSentinel(
                allocator,
                "Unsupported game version '{any}', the script will exit. Contact the script author for support.",
                .{version},
                0,
            ) catch unreachable;
            defer allocator.free(text);
            log.err("{s}", .{text});
            _ = root.MessageBoxA(null, text, "Error", .{
                .icon_type = .stop,
            });
            return;
        },
    };

    log.debug("Setting up global pointers with offsets:", .{});
    log.debug("\tiSPInitBitset  = {d}", .{g_offset.iSPInitBitset});
    log.debug("\tvBHCheckpoints = {d}", .{g_offset.vBHCheckpoints});
    log.debug("\tiBHPathIndexes = {d}", .{g_offset.iBHPathIndexes});
    log.debug("\tsBHPath        = {d}", .{g_offset.sBHPath});

    g = .{
        // Get current Single Player bitset
        .iSPInitBitset = @ptrCast(try Hook.getGlobalPtr(g_offset.iSPInitBitset)),
        // Get current Beast Hunt checkpoints
        .vBHCheckpoints = @ptrCast(try Hook.getGlobalPtr(g_offset.vBHCheckpoints)),
        // Get current Beast Hunt path indexes
        .iBHPathIndexes = @ptrCast(try Hook.getGlobalPtr(g_offset.iBHPathIndexes)),
        // Get current Beast Hunt path nodes
        .sBHPath = @ptrCast(try Hook.getGlobalPtr(g_offset.sBHPath)),
    };

    log.debug("Global pointers initialized successfully", .{});

    // Reset visited paths nodes
    log.info("Resetting visited paths nodes...", .{});
    resetVisited();

    // Print globals for debugging
    log.debug("Dumping globals for debugging...", .{});
    dumpGlobals();

    log.debug("Entering main update loop", .{});
    while (true) {
        try update();
        try Hook.wait(0);
    }
}

// As path state is stored here, reloading the script will reset
// path between checkpoints but not the checkpoints themselves.
var visitedPathsNodes: [MAX_PATH_COUNT][NODES_PER_PATH]?bool = undefined;

// Track previous state to log only on changes
var prevBeastState: struct {
    peyotesCollected: bool = false,
    huntCompleted: bool = false,
    killedAndUnlocked: bool = false,
    lastPeyoteDay: u3 = 0,
    currentCheckpoint: u4 = 0,
    nextCheckpoint: u4 = 0,
    callMade: bool = false,
} = .{};

fn update() Hook.Error!void {
    // Get player ped and position
    const player = try Natives.Player.playerId();
    const playerPed = try Natives.Player.playerPedId();
    const playerModel = try Natives.Entity.getEntityModel(playerPed);
    const playerPos = try Natives.Entity.getEntityCoords(playerPed, w.TRUE);

    // Log state changes
    if (prevBeastState.peyotesCollected != g.iSPInitBitset.BEAST_PEYOTES_COLLECTED) {
        log.info("State change: BEAST_PEYOTES_COLLECTED: {any} -> {any}", .{ prevBeastState.peyotesCollected, g.iSPInitBitset.BEAST_PEYOTES_COLLECTED });
        prevBeastState.peyotesCollected = g.iSPInitBitset.BEAST_PEYOTES_COLLECTED;
    }
    if (prevBeastState.huntCompleted != g.iSPInitBitset.BEAST_HUNT_COMPLETED) {
        log.info("State change: BEAST_HUNT_COMPLETED: {any} -> {any}", .{ prevBeastState.huntCompleted, g.iSPInitBitset.BEAST_HUNT_COMPLETED });
        prevBeastState.huntCompleted = g.iSPInitBitset.BEAST_HUNT_COMPLETED;
    }
    if (prevBeastState.killedAndUnlocked != g.iSPInitBitset.BEAST_KILLED_AND_UNLOCKED) {
        log.info("State change: BEAST_KILLED_AND_UNLOCKED: {any} -> {any}", .{ prevBeastState.killedAndUnlocked, g.iSPInitBitset.BEAST_KILLED_AND_UNLOCKED });
        prevBeastState.killedAndUnlocked = g.iSPInitBitset.BEAST_KILLED_AND_UNLOCKED;
    }
    if (prevBeastState.lastPeyoteDay != g.iSPInitBitset.BEAST_LAST_PEYOTE_DAY) {
        log.info("State change: BEAST_LAST_PEYOTE_DAY: {d} -> {d}", .{ prevBeastState.lastPeyoteDay, g.iSPInitBitset.BEAST_LAST_PEYOTE_DAY });
        prevBeastState.lastPeyoteDay = g.iSPInitBitset.BEAST_LAST_PEYOTE_DAY;
    }
    if (prevBeastState.currentCheckpoint != g.iSPInitBitset.BEAST_CURRENT_CHECKPOINT) {
        log.info("State change: BEAST_CURRENT_CHECKPOINT: {d} -> {d}", .{ prevBeastState.currentCheckpoint, g.iSPInitBitset.BEAST_CURRENT_CHECKPOINT });
        prevBeastState.currentCheckpoint = g.iSPInitBitset.BEAST_CURRENT_CHECKPOINT;
    }
    if (prevBeastState.nextCheckpoint != g.iSPInitBitset.BEAST_NEXT_CHECKPOINT) {
        log.info("State change: BEAST_NEXT_CHECKPOINT: {d} -> {d}", .{ prevBeastState.nextCheckpoint, g.iSPInitBitset.BEAST_NEXT_CHECKPOINT });
        prevBeastState.nextCheckpoint = g.iSPInitBitset.BEAST_NEXT_CHECKPOINT;
    }
    // Omit callMade as it's handled below

    if (!g.iSPInitBitset.BEAST_PEYOTES_COLLECTED or
        g.iSPInitBitset.BEAST_HUNT_COMPLETED or
        g.iSPInitBitset.BEAST_KILLED_AND_UNLOCKED or
        g.iSPInitBitset.BEAST_LAST_PEYOTE_DAY != 7 or
        playerModel != Joaat.atStringHash(u32, "IG_ORLEANS"))
    {
        resetVisited();
        return;
    }

    // Check if player ped exists and control is on (e.g. not in a cutscene)
    if (try Natives.Entity.doesEntityExist(playerPed) == w.FALSE or
        try Natives.Player.isPlayerControlOn(player) == w.FALSE)
    {
        return;
    }

    // Make a call every time
    if (prevBeastState.callMade != g.iSPInitBitset.BEAST_CALL_MADE) {
        prevBeastState.callMade = g.iSPInitBitset.BEAST_CALL_MADE;
        if (!g.iSPInitBitset.BEAST_CALL_MADE) {
            g.iSPInitBitset.BEAST_CALL_MADE = true;
        }
    }

    // Path drawing and node visiting
    {
        const currentCP = g.iSPInitBitset.BEAST_CURRENT_CHECKPOINT;
        const nextCP = g.iSPInitBitset.BEAST_NEXT_CHECKPOINT;
        const pathIndex = g.iBHPathIndexes.data[currentCP].data[nextCP];

        // Path index can be -1 if there's no valid path between checkpoints
        if (pathIndex < 0 or pathIndex >= MAX_PATH_COUNT) {
            log.warn("Invalid path index {d} between checkpoints {d} and {d}", .{ pathIndex, currentCP, nextCP });
            return;
        }
        const index: usize = @intCast(pathIndex);
        const path = g.sBHPath.data[index];
        const visitedNodes = &visitedPathsNodes[index];

        // Draw path from current to next checkpoint
        // through all nodes
        {
            const currentCheckpointPos = g.vBHCheckpoints.data[currentCP];
            const nextCheckpointPos = g.vBHCheckpoints.data[nextCP];

            // Current checkpoint to first node
            try Natives.Graphics.drawLine(
                currentCheckpointPos,
                path.nodes[0],
                255,
                255,
                0,
                255,
            );

            // Last node to next checkpoint
            try Natives.Graphics.drawLine(
                path.nodes[path.length - 1],
                nextCheckpointPos,
                255,
                0,
                0,
                255,
            );

            // Between nodes
            for (0..path.length - 1) |i| {
                const node1 = path.nodes[i];
                const node2 = path.nodes[i + 1];

                try Natives.Graphics.drawLine(
                    node1,
                    node2,
                    0,
                    255,
                    0,
                    255,
                );
            }

            // Next checkpoint marker
            try Natives.Graphics.drawMarker(
                28,
                nextCheckpointPos,
                .{
                    .x = 0,
                    .y = 0,
                    .z = 0,
                },
                .{
                    .x = 0,
                    .y = 180,
                    .z = 0,
                },
                .{
                    .x = 2,
                    .y = 2,
                    .z = 2,
                },
                255,
                255 / 2,
                0,
                255 / 4,
                0,
                1,
                1,
                0,
                null,
                null,
                0,
            );

            // Draw line from player to next checkpoint
            try Natives.Graphics.drawLine(
                playerPos,
                nextCheckpointPos,
                255,
                255 / 2,
                0,
                255,
            );
        }

        // Draw line and sphere to first unvisited node
        {
            var visitedCount: usize = 0;
            var unvisitedCount: usize = 0;
            for (0..path.length) |j| {
                if (visitedNodes[j]) |v| {
                    if (v) visitedCount += 1 else unvisitedCount += 1;
                }
            }

            for (0..path.length) |i| {
                const node = path.nodes[i];

                if (visitedNodes[i]) |visited| {
                    if (!visited) {

                        // Mark node as visited when player is close enough
                        const dist = try Natives.Builtin.vdist2(playerPos, node);
                        if (dist < PATH_NODE_RADIUS) // Tight radius check, just to be sure
                        {
                            visitedNodes[i] = true;
                            log.info(
                                "Visited node {d} at ({d:>8.3}, {d:>8.3}, {d:>7.3}) - {d}/{d}",
                                .{ i, node.x, node.y, node.z, visitedCount + 1, visitedCount + unvisitedCount },
                            );
                        }

                        // Draw sphere to first unvisited node
                        try Natives.Graphics.drawMarkerSphere(
                            node,
                            comptime std.math.sqrt(PATH_NODE_RADIUS),
                            0,
                            255,
                            255,
                            1.0 / 3.0,
                        );

                        // Draw line to first unvisited node
                        try Natives.Graphics.drawLine(
                            playerPos,
                            node,
                            0,
                            255,
                            255,
                            255,
                        );

                        // Exit after first unvisited node
                        break;
                    }
                }
            }
        }
    }
}

fn resetVisited() void {
    // Nullify visited paths nodes
    for (&visitedPathsNodes) |*path| {
        for (path) |*node| {
            node.* = null;
        }
    }

    // Fill visited nodes paths with false where node exists
    for (g.sBHPath.data, 0..) |path, i| {
        for (0..path.length) |j| {
            const node = &visitedPathsNodes[i][j];
            if (node.* == null) {
                node.* = false;
            }
        }
    }

    // Reset call made state
    if (g.iSPInitBitset.BEAST_CALL_MADE) {
        g.iSPInitBitset.BEAST_CALL_MADE = false;
    }
}

fn dumpGlobals() void {
    const dumpSPInitBitset = true;
    const dumpBHCheckpoints = true;
    const dumpBHPathIndexes = true;
    const dumpBHPath = true;
    std.debug.print("g = {{\n", .{});
    if (dumpSPInitBitset) {
        std.debug.print("  iSPInitBitset: {{\n", .{});
        std.debug.print("    INSTALL_SCREEN_FINISHED: {any},\n", .{g.iSPInitBitset.INSTALL_SCREEN_FINISHED});
        std.debug.print("    TITLE_SEQUENCE_DISPLAYED: {any},\n", .{g.iSPInitBitset.TITLE_SEQUENCE_DISPLAYED});
        std.debug.print("    TURN_ON_LOST_BIKER_GROUP: {any},\n", .{g.iSPInitBitset.TURN_ON_LOST_BIKER_GROUP});
        std.debug.print("    RESTORE_SLEEP_MODE: {any},\n", .{g.iSPInitBitset.RESTORE_SLEEP_MODE});
        std.debug.print("    LOADED_DIRECTLY_INTO_MISSION: {any},\n", .{g.iSPInitBitset.LOADED_DIRECTLY_INTO_MISSION});
        std.debug.print("    UNLOCK_SHINE_A_LIGHT: {any},\n", .{g.iSPInitBitset.UNLOCK_SHINE_A_LIGHT});
        std.debug.print("    SHRINK_SESSION_ATTENDED: {any},\n", .{g.iSPInitBitset.SHRINK_SESSION_ATTENDED});
        std.debug.print("    BEAST_PEYOTES_COLLECTED: {any},\n", .{g.iSPInitBitset.BEAST_PEYOTES_COLLECTED});
        std.debug.print("    BEAST_HUNT_COMPLETED: {any},\n", .{g.iSPInitBitset.BEAST_HUNT_COMPLETED});
        std.debug.print("    BEAST_FIGHT_FAILED: {any},\n", .{g.iSPInitBitset.BEAST_FIGHT_FAILED});
        std.debug.print("    BEAST_KILLED_AND_UNLOCKED: {any},\n", .{g.iSPInitBitset.BEAST_KILLED_AND_UNLOCKED});
        std.debug.print("    BEAST_LAST_PEYOTE_DAY: {any},\n", .{g.iSPInitBitset.BEAST_LAST_PEYOTE_DAY});
        std.debug.print("    BEAST_CURRENT_CHECKPOINT: {any},\n", .{g.iSPInitBitset.BEAST_CURRENT_CHECKPOINT});
        std.debug.print("    BEAST_NEXT_CHECKPOINT: {any},\n", .{g.iSPInitBitset.BEAST_NEXT_CHECKPOINT});
        std.debug.print("    BEAST_CALL_MADE: {any},\n", .{g.iSPInitBitset.BEAST_CALL_MADE});
        std.debug.print("  }},\n", .{});
    }
    if (dumpBHCheckpoints) {
        std.debug.print("  vBHCheckpoints: {{\n", .{});
        std.debug.print("    size: {any},\n", .{g.vBHCheckpoints.size});
        std.debug.print("    data: {{\n", .{});
        for (g.vBHCheckpoints.data, 0..) |checkpoint, i| {
            std.debug.print("      {d:2}: ({d:>8.3}, {d:>8.3}, {d:>7.4}),\n", .{
                i,
                checkpoint.x,
                checkpoint.y,
                checkpoint.z,
            });
        }
        std.debug.print("    }},\n", .{});
        std.debug.print("  }},\n", .{});
    }
    if (dumpBHPathIndexes) {
        std.debug.print("  iBHPathIndexes: {{\n", .{});
        std.debug.print("    size: {any}\n", .{g.iBHPathIndexes.size});
        std.debug.print("    data: {{", .{});
        for (g.iBHPathIndexes.data[0].data, 0..) |_, i| {
            std.debug.print("{d:4} ", .{i});
        }
        std.debug.print("\n", .{});
        for (g.iBHPathIndexes.data, 0..) |checkpoint, i| {
            std.debug.print("      {d:2}: [ ", .{i});
            for (checkpoint.data) |pathIndex| {
                if (@as(i32, @truncate(pathIndex)) == -1) {
                    std.debug.print("  ?, ", .{});
                } else {
                    std.debug.print("{d:3}, ", .{
                        @as(i32, @truncate(pathIndex)),
                    });
                }
            }
            std.debug.print("], ({d})\n", .{checkpoint.size});
        }
        std.debug.print("    }},\n", .{});
        std.debug.print("  }},\n", .{});
    }
    if (dumpBHPath) {
        std.debug.print("  sBHPath: {{ ", .{});
        std.debug.print("size: {any}\n", .{g.sBHPath.size});
        std.debug.print("    data: [\n", .{});
        for (g.sBHPath.data, 0..) |path, i| {
            if (path.length == 0) {
                continue; // Skip empty paths
            }

            std.debug.print("      {d}: {{ ", .{i});
            std.debug.print("length: {d}, ", .{path.length});
            std.debug.print("size: {d}\n", .{path.size});
            std.debug.print("        nodes: [\n", .{});
            for (0..path.length) |j| {
                const node = path.nodes[j];
                std.debug.print("          {d}: ({d:>8.3}, {d:>8.3}, {d:>7.3}),\n", .{
                    j,
                    node.x,
                    node.y,
                    node.z,
                });
            }
            std.debug.print("        ],\n", .{});
            std.debug.print("      }},\n", .{});
        }
        std.debug.print("    ],\n", .{});
        std.debug.print("  }},\n", .{});
    }
    std.debug.print("}};\n", .{});
}

test "script" {
    const testing = std.testing;

    testing.refAllDeclsRecursive(@This());
}
