# GTA V Beast Hunt Helper

Mod for Grand Theft Auto V that will help you in completing *The Beast Hunt*
by drawing a lines from player to target checkpoint through path nodes.
So you would not need to use your hearing abilities to find path nodes anymore.
Beast Hunt have static path nodes between checkpoints, but selection of next checkpoint is random,
so video guides aren't very helpful, but this mod is.

## Building

1. Install [Zig](https://ziglang.org/download/)
2. Run `zig build` in the root directory of the project
3. The output will be in `./zig-out/bin/BeastHuntHelper.dll`

## Usage

1. Download and install latest version of [ScriptHookV](https://www.dev-c.com/gtav/scripthookv/)
2. Download or build this mod as described above.
3. Copy `BeastHuntHelper.dll` to root of your GTA V installation directory, and change extension to `.asi` (e.g. `BeastHuntHelper.asi`).
4. Start the game.
5. Find the last golden peyote on Saturday between 5:30 AM and 8:00 AM when the weather is foggy.
6. Save the game before eating the last golden peyote, as it will start the beast hunt quest.
7. Eat the last golden peyote to start the beast hunt quest. You will be transformed into a beast (Yeti/Sasquatch/Bigfoot) and the game will start tracking your path nodes and checkpoints.
8. Now you'll:
      - See a couple of colored lines on the screen:
         - <b style="color:yellow">Yellow</b> - line from current checkpoint to the first path node.
         - <b style="color:green">Green</b> - line between path nodes.
         - <b style="color:red">Red</b> - line from last path node to the next checkpoint.
         - <b style="color:cyan">Cyan</b> - line from player to the next path node (that's what you should follow).
         - <b style="color:orange">Orange</b> - line from player to the next checkpoint (that's what you should follow after all path nodes are done).
      - Meet a couple of spheres:
         - <b style="color:cyan">Cyan</b> - next path node (that's where you need to go).
         - <b style="color:orange">Orange</b> - next checkpoint (that's where you need to go after path nodes are done).
9. Follow the <b style="color:cyan">cyan</b> line to the next path node (the <b style="color:cyan">cyan</b> sphere) and when no more path nodes are left, follow the <b style="color:orange">orange</b> line to the next checkpoint (the <b style="color:orange">orange</b> sphere).
10. If path nodes are followed correctly up to the next checkpoint, the game will automatically progress to the next checkpoint and next set of path nodes and new checkpoint will be automatically drawn on the screen.
      - If not, try to reload save and start again from step 7 (inclusive).
      - Also check the [troubleshooting](#troubleshooting) section below.
11. Repeat steps 9-10 until you reach the final checkpoint and meet *The Beast*, and you will have to fight it.
      - Do not try to use something like *God Mode* as game have checks for that and will:
         - Reset *The Beast* health to full.
         - Try to drop your health.
         - Make fight more difficult.
12. After defeating *The Beast*, you will be able to return to the normal world and continue playing the game.

![image](https://img.gta5-mods.com/q95/images/gtav-beast-hunt-helper/ee7850-Screenshot_20250701_093903-min.png)

## Troubleshooting

Beast script is very *fragile* don't do nothing unusual, just follow the line and that's all.
Also, this mod has it's own state which tracks the progress between checkpoints, a.k.a. path nodes, as it's very hard to completely hook script state as not everything this mod needs is stored in global variables.

## Contributing

Feel free to open issues or pull requests if you have any suggestions or improvements.

But remember: [Talk is cheap, send patches.](https://fxtwitter.com/FFmpeg/status/1762805900035686805)
