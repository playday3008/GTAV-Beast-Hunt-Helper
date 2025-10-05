const std = @import("std");
const w = std.os.windows;

const root = @import("root");

const ScriptHookZig = @import("ScriptHookZig");
const Hook = ScriptHookZig.Hook;
const Types = ScriptHookZig.Types;
const Joaat = ScriptHookZig.Joaat;
const Natives = @import("natives.zig");

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
    iSPInitBitset: *packed struct {
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
    },
    iBHPathIndexes: *extern struct {
        size: u64,
        data: [CHECKPOINT_COUNT]extern struct {
            size: u64,
            data: [CHECKPOINT_COUNT]i64,
        },
    },
    sBHPath: *extern struct {
        size: u64,
        data: [MAX_PATH_COUNT]extern struct {
            length: u64,
            size: u64,
            nodes: [NODES_PER_PATH]Types.Vector3,

            comptime {
                const expected_size = 14 * @sizeOf(u64);
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
    },
} = undefined;

pub fn scriptMain() callconv(.c) void {
    g_offset = switch (Hook.getGameVersionGTAV()) {
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
        .VER_EN_1_0_889_22 => .{
            .iSPInitBitset = 114370 + 10020 + 25,
            .vBHCheckpoints = 111119,
            .iBHPathIndexes = 111119 + 463,
            .sBHPath = 111119 + 463 + 266,
        },
        else => |version| {
            std.log.err("Unsupported game version: {any}", .{
                version,
            });
            return;
        },
    };

    g = .{
        // Get current Single Player bitset
        .iSPInitBitset = @ptrCast(Hook.getGlobalPtr(g_offset.iSPInitBitset)),
        // Get current Beast Hunt checkpoints
        .vBHCheckpoints = @ptrCast(Hook.getGlobalPtr(g_offset.vBHCheckpoints)),
        // Get current Beast Hunt path indexes
        .iBHPathIndexes = @ptrCast(Hook.getGlobalPtr(g_offset.iBHPathIndexes)),
        // Get current Beast Hunt path nodes
        .sBHPath = @ptrCast(Hook.getGlobalPtr(g_offset.sBHPath)),
    };

    // Reset visited paths nodes
    resetVisited();

    // Print globals for debugging
    dumpGlobals();

    while (true) {
        update();
        Hook.wait(0);
    }
}

// As path state is stored here, reloading the script will reset
// path between checkpoints but not the checkpoints themselves.
var visitedPathsNodes: [MAX_PATH_COUNT][NODES_PER_PATH]?bool = undefined;
var callTick: i64 = 0;

fn update() void {
    // Get player ped and position
    const player = Natives.Player.playerId();
    const playerPed = Natives.Player.playerPedId();
    const playerModel = Natives.Entity.getEntityModel(playerPed);
    const playerPos = Natives.Entity.getEntityCoords(playerPed, w.TRUE);

    if (!g.iSPInitBitset.BEAST_PEYOTES_COLLECTED or
        g.iSPInitBitset.BEAST_HUNT_COMPLETED or
        g.iSPInitBitset.BEAST_KILLED_AND_UNLOCKED or
        g.iSPInitBitset.BEAST_LAST_PEYOTE_DAY != 7 or
        playerModel != Joaat.atStringHash(u32, "IG_ORLEANS"))
    {
        g.iSPInitBitset.BEAST_CALL_MADE = false;
        resetVisited();
        return;
    }

    // Check if player ped exists and control is on (e.g. not in a cutscene)
    if (Natives.Entity.doesEntityExist(playerPed) == w.FALSE or
        Natives.Player.isPlayerControlOn(player) == w.FALSE)
    {
        return;
    }

    {
        const index: usize = @intCast(g.iBHPathIndexes.data[g.iSPInitBitset.BEAST_CURRENT_CHECKPOINT].data[g.iSPInitBitset.BEAST_NEXT_CHECKPOINT]);
        const path = g.sBHPath.data[index];
        const visitedNodes = &visitedPathsNodes[index];

        // Draw path from current to next checkpoint
        // through all nodes
        {
            // Current checkpoint to first node
            Natives.Graphics.drawLine(
                g.vBHCheckpoints.data[g.iSPInitBitset.BEAST_CURRENT_CHECKPOINT],
                path.nodes[0],
                255,
                255,
                0,
                255,
            );

            // Last node to next checkpoint
            Natives.Graphics.drawLine(
                path.nodes[path.length - 1],
                g.vBHCheckpoints.data[g.iSPInitBitset.BEAST_NEXT_CHECKPOINT],
                255,
                0,
                0,
                255,
            );

            // Between nodes
            for (0..path.length - 1) |i| {
                const node1 = path.nodes[i];
                const node2 = path.nodes[i + 1];

                Natives.Graphics.drawLine(
                    node1,
                    node2,
                    0,
                    255,
                    0,
                    255,
                );
            }

            // Next checkpoint marker
            Natives.Graphics.drawMarker(
                28,
                g.vBHCheckpoints.data[g.iSPInitBitset.BEAST_NEXT_CHECKPOINT],
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
            Natives.Graphics.drawLine(
                playerPos,
                g.vBHCheckpoints.data[g.iSPInitBitset.BEAST_NEXT_CHECKPOINT],
                255,
                255 / 2,
                0,
                255,
            );
        }

        // Draw line and sphere to first unvisited node
        {
            for (0..path.length) |i| {
                const node = path.nodes[i];

                if (visitedNodes[i]) |visited| {
                    if (!visited) {

                        // Mark node as visited when player is close enough
                        const dist = Natives.Builtin.vdist2(playerPos, node);
                        if (dist < PATH_NODE_RADIUS) // Tight radius check, just to be sure
                        {
                            visitedNodes[i] = true;
                            std.log.debug(
                                "Visited: ({d:>8.3}, {d:>8.3}, {d:>7.3})",
                                .{ node.x, node.y, node.z },
                            );
                        }

                        // Draw sphere to first unvisited node
                        Natives.Graphics.drawMarkerSphere(
                            node,
                            comptime std.math.sqrt(PATH_NODE_RADIUS),
                            0,
                            255,
                            255,
                            1.0 / 3.0,
                        );

                        // Draw line to first unvisited node
                        Natives.Graphics.drawLine(
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

    // Make a call every 10 seconds
    if (std.time.milliTimestamp() - callTick > 10_000) {
        callTick = std.time.milliTimestamp();

        // Call Beast Hunt script
        g.iSPInitBitset.BEAST_CALL_MADE = true;
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
}

fn dumpGlobals() void {
    const dumpSPInitBitset = true;
    const dumpBHCheckpoints = false;
    const dumpBHPathIndexes = false;
    const dumpBHPath = false;
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
            std.debug.print("      {d:2}: ({d:>8.3}, {d:>8.3}, {d:>7.3}),\n", .{
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
