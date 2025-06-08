const std = @import("std");
const w = std.os.windows;

const root = @import("root");

const ScriptHookV = @import("natives/ScriptHookV.zig");
const Natives = @import("natives/natives.zig");
const Enums = @import("natives/enums.zig");
const Types = @import("natives/types.zig");

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
        BEAST_Next_CHECKPOINT: u4,
        BEAST_Call_Made: bool,
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
            .iBHPathIndexes = 111717,
            .sBHPath = 111850,
        },
        .VER_1_0_3179_0 => .{
            .iSPInitBitset = 114372 + 10019 + 25,
            .vBHCheckpoints = 111121,
            .iBHPathIndexes = 111584,
            .sBHPath = 111850,
        },
        .VER_1_0_3258_0, .VER_1_0_3323_0 => .{
            .iSPInitBitset = 113969 + 10019 + 25,
            .vBHCheckpoints = 110718,
            .iBHPathIndexes = 111181,
            .sBHPath = 111447,
        },
        .VER_1_0_3407_0, .VER_1_0_3504_0 => .{
            .iSPInitBitset = 114135 + 10020 + 25,
            .vBHCheckpoints = 110884,
            .iBHPathIndexes = 111347,
            .sBHPath = 111613,
        },
        .VER_EN_1_0_814_9 => .{
            .iSPInitBitset = 124207,
            .vBHCheckpoints = 110911,
            .iBHPathIndexes = 111374,
            .sBHPath = 111640,
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
    //g.iSPInitBitset.print();

    if (!g.iSPInitBitset.BEAST_PEYOTES_COLLECTED or
        g.iSPInitBitset.BEAST_HUNT_COMPLETED or
        g.iSPInitBitset.BEAST_KILLED_AND_UNLOCKED or
        g.iSPInitBitset.BEAST_LAST_PEYOTE_DAY != 7 or
        playerModel != Joaat.joaat("IG_ORLEANS"))
    {
        return;
    }

    // Check if player ped exists and control is on (e.g. not in a cutscene)
    if (Natives.Entity.doesEntityExist(playerPed) == w.FALSE or
        Natives.Player.isPlayerControlOn(player) == w.FALSE)
    {
        return;
    }

    // Update current checkpoint and nodes if they have changed
    if (currentCheckpoint != g.iSPInitBitset.BEAST_CURRENT_CHECKPOINT or
        nextCheckpoint != g.iSPInitBitset.BEAST_Next_CHECKPOINT)
    {
        currentCheckpoint = g.iSPInitBitset.BEAST_CURRENT_CHECKPOINT;
        nextCheckpoint = g.iSPInitBitset.BEAST_Next_CHECKPOINT;

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
            if (dist < PATH_NODE_RADIUS and // Tight radius check, just to be sure
                Natives.Ped.isPedInAnyVehicle(playerPed, w.TRUE) == w.FALSE) // Just to be sure
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
        g.iSPInitBitset.BEAST_Call_Made = true;
    }
}
