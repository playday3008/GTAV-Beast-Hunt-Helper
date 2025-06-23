const std = @import("std");
const w = std.os.windows;

const root = @import("root");

const ScriptHookV = @import("ScriptHookV");
const Enums = ScriptHookV.Enums;
const Types = ScriptHookV.Types;
const Natives = @import("natives.zig");

const Joaat = @import("joaat.zig");

var rand: std.Random.DefaultPrng = undefined;

const CHECKPOINT_COUNT = 11;
const MAX_PATH_COUNT = 64;
const NODES_PER_PATH = 4;
const PATH_NODE_RADIUS = 17.0;

var gp: struct {
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
    rand = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));

    gp = switch (ScriptHookV.getGameVersion()) {
        // Source: https://github.com/calamity-inc/GTA-V-Decompiled-Scripts
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
        .VER_1_0_3258_0, .VER_1_0_3323_0 => .{
            .iSPInitBitset = 113969 + 10019 + 25,
            .vBHCheckpoints = 110718,
            .iBHPathIndexes = 110718 + 463,
            .sBHPath = 110718 + 463 + 266,
        },
        .VER_1_0_3407_0, .VER_1_0_3504_0 => .{
            .iSPInitBitset = 114135 + 10020 + 25,
            .vBHCheckpoints = 110884,
            .iBHPathIndexes = 110884 + 463,
            .sBHPath = 110884 + 463 + 266,
        },
        // Source: me
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
        else => {
            std.log.err("Unsupported game version: {any}", .{
                ScriptHookV.getGameVersion(),
            });
            return;
        },
    };

    while (true) {
        tick();
        ScriptHookV.wait(0);
    }
}

// As path state is stored here,
// reloading the script will reset path between checkpoints
// but not the checkpoints themselves.
var currentCheckpoint: u4 = 0;
var nextCheckpoint: u4 = 0;
var currentNodes: std.DoublyLinkedList(*const Types.Vector3) = .{};
var callTick: i64 = 0;
var dumpTick: i64 = 0;

var dumpGlobalsOnce = std.once(dumpGlobals);

fn tick() void {
    // Get player ped and position
    const player = Natives.Player.playerId();
    const playerPed = Natives.Player.playerPedId();
    const playerModel = Natives.Entity.getEntityModel(playerPed);
    const playerPos = Natives.Entity.getEntityCoords(playerPed, w.TRUE);

    g = .{
        // Get current Single Player bitset
        .iSPInitBitset = @ptrCast(ScriptHookV.getGlobalPtr(gp.iSPInitBitset)),
        // Get current Beast Hunt checkpoints
        .vBHCheckpoints = @ptrCast(ScriptHookV.getGlobalPtr(gp.vBHCheckpoints)),
        // Get current Beast Hunt path indexes
        .iBHPathIndexes = @ptrCast(ScriptHookV.getGlobalPtr(gp.iBHPathIndexes)),
        // Get current Beast Hunt path nodes
        .sBHPath = @ptrCast(ScriptHookV.getGlobalPtr(gp.sBHPath)),
    };

    // Dump globals every 2.5 seconds
    //if ((std.time.milliTimestamp() - dumpTick) >= 2500) {
    //    dumpTick = std.time.milliTimestamp();
    //    dumpGlobals();
    //}
    dumpGlobalsOnce.call();

    if (!g.iSPInitBitset.BEAST_PEYOTES_COLLECTED or
        g.iSPInitBitset.BEAST_HUNT_COMPLETED or
        g.iSPInitBitset.BEAST_KILLED_AND_UNLOCKED or
        g.iSPInitBitset.BEAST_LAST_PEYOTE_DAY != 7 or
        playerModel != Joaat.joaat("IG_ORLEANS"))
    {
        g.iSPInitBitset.BEAST_CALL_MADE = false;
        return;
    }

    // Check if player ped exists and control is on (e.g. not in a cutscene)
    if (Natives.Entity.doesEntityExist(playerPed) == w.FALSE or
        Natives.Player.isPlayerControlOn(player) == w.FALSE)
    {
        return;
    }

    // Disable ability to enter vehicles
    Natives.Player.setPlayerMayNotEnterAnyVehicle(player);

    // Update current checkpoint and nodes if they have changed
    if (currentCheckpoint != g.iSPInitBitset.BEAST_CURRENT_CHECKPOINT or
        nextCheckpoint != g.iSPInitBitset.BEAST_NEXT_CHECKPOINT)
    {
        currentCheckpoint = g.iSPInitBitset.BEAST_CURRENT_CHECKPOINT;
        nextCheckpoint = g.iSPInitBitset.BEAST_NEXT_CHECKPOINT;

        std.log.info("Checkpoint updated: {d} -> {d}", .{
            currentCheckpoint,
            nextCheckpoint,
        });

        // Clear current nodes if next checkpoint changes
        {
            while (currentNodes.pop()) |node| {
                root.arena.allocator().destroy(node);
            }
            currentNodes = .{};
        }

        // Get path nodes between current and next checkpoint
        const path = g.iBHPathIndexes.data[currentCheckpoint].data[nextCheckpoint];
        const nodes = g.sBHPath.data[@intCast(path)].nodes;

        for (&nodes) |*node| {
            if (node.x == 0 and node.y == 0 and node.z == 0) {
                continue; // Skip zero coordinates
            }

            if (std.meta.eql(node.*, g.vBHCheckpoints.data[nextCheckpoint])) {
                continue; // Skip if node is the next checkpoint
            }

            const new = @TypeOf(currentNodes).Node{
                .data = node,
            };
            const newAllocated = root.arena.allocator().create(@TypeOf(new)) catch |err| {
                std.log.err("Failed to allocate memory for new node: {any}", .{err});
                return;
            };
            newAllocated.* = new;
            currentNodes.append(newAllocated);
            std.log.debug(
                "Added node: ({d:>7.2}, {d:>7.2}, {d:>6.2})",
                .{ node.x, node.y, node.z },
            );
        }
    }

    // Pop nodes that are marked as reached
    {
        if (currentNodes.first) |first| {
            const dist = Natives.Builtin.vdist2(playerPos, first.data.*);
            if (dist < PATH_NODE_RADIUS) // Tight radius check, just to be sure
            {
                root.arena.allocator().destroy(currentNodes.popFirst().?);
                std.log.debug(
                    "Reached node, removing: ({d:>7.2}, {d:>7.2}, {d:>6.2})",
                    .{ first.data.x, first.data.y, first.data.z },
                );
            }
        }
    }

    // Draw lines from player to current checkpoint through nodes
    {
        if (currentNodes.first) |first| {
            Natives.Graphics.drawLine(
                playerPos,
                first.data.*,
                255,
                255,
                0,
                255,
            );

            var item = currentNodes.first;
            while (item) |node| : (item = node.next) {
                if (node.next) |next| {
                    Natives.Graphics.drawLine(
                        node.data.*,
                        next.data.*,
                        0,
                        255,
                        0,
                        255,
                    );
                }
            }
        }

        if (currentNodes.last) |last| {
            Natives.Graphics.drawLine(
                last.data.*,
                g.vBHCheckpoints.data[nextCheckpoint],
                255,
                0,
                0,
                255,
            );
        } else {
            Natives.Graphics.drawLine(
                playerPos,
                g.vBHCheckpoints.data[nextCheckpoint],
                255,
                0,
                0,
                255,
            );
        }
    }

    // Call the Beast every 10 seconds
    if ((std.time.milliTimestamp() - callTick) >= 10000) {
        callTick = std.time.milliTimestamp();
        g.iSPInitBitset.BEAST_CALL_MADE = true;
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
                std.debug.print("{d:3}, ", .{@as(i32, @truncate(pathIndex))});
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
