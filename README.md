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
6. Now you'll:
   - See a couple of colored lines on the screen:
      - <span style="color:yellow">Yellow</span> - line from current checkpoint to the first path node.
      - <span style="color:green">Green</span> - line between path nodes.
      - <span style="color:red">Red</span> - line from last path node to the next checkpoint.
      - <span style="color:cyan">Cyan</span> - line from player to the next path node (that's what you should follow).
      - <span style="color:orange">Orange</span> - line from player to the next checkpoint (that's what you should follow after all path nodes are done).
   - Meet a couple of spheres:
      - <span style="color:cyan">Cyan</span> - next path node (that's where you need to go).
      - <span style="color:orange">Orange</span> - next checkpoint (that's where you need to go after path nodes are done).

## Tips

Beast script is very *fragile* don't do nothing unusual, just follow the line and that's all.
This mod can't track script state as it isn't stored in global variable, so mod have it's own state which can desync from game script, if anything unexpected happens.

## Contributing

Feel free to open issues or pull requests if you have any suggestions or improvements.

But remember: [Talk is cheap, send patches.](https://fxtwitter.com/FFmpeg/status/1762805900035686805)
