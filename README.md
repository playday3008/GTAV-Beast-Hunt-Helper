# GTA V Beast/Yeti/Sasquatch/Bigfoot Hunt Helper

Mod for Grand Theft Auto V that will draw a line from player to target checkpoint through path nodes.
So you would not need to use your hearing abilities to find path nodes anymore.

## Building

1. Install [Zig](https://ziglang.org/download/)
2. Run `zig build` in the root directory of the project
3. The output will be in `./zig-out/bin/BeastHuntHelper.dll`

## Usage

1. Download and Install latest version of [ScriptHookV](https://www.dev-c.com/gtav/scripthookv/)
2. Download or build this mod as described above.
3. Copy `BeastHuntHelper.dll` to root of your GTA V installation directory, and change extension to `.asi` (e.g. `BeastHuntHelper.asi`).
4. Start the game.
5. Eat last golden peyote on Saturday between 5:30 AM and 8:00 AM when the weather is foggy.
6. You'll see yellow, green and red lines on the screen.
   - Yellow line is the path to the next path node.
   - Green line is the path between path nodes.
   - Red line is the path from last path node or player to the checkpoint.
7. Just follow the line that originates from the player.

## Tips

Beast script is very *fragile* don't do nothing unusual, just follow the line and that's all.
This mod can't track script state as it isn't stored in global variable, so mod have it's own state which can desync from game script, if anything unexpected happens.

## Contributing

Feel free to open issues or pull requests if you have any suggestions or improvements.

But remember: [Talk is cheap, send patches.](https://x.com/FFmpeg/status/1762805900035686805)
