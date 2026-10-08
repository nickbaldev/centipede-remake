# Centipede Remake

A remake of the classic arcade game *Centipede* built in Lua for TIC-80.

## Features

- Player movement and shooting
- Segmented centipede movement and splitting
- Mushrooms with destructible health
- Spider enemy with jumping movement
- Collision detection between the player, enemies, bullets, and mushrooms
- Score and lives system
- Multiple levels with increasing difficulty
- Embedded game sprites and sound effects

## Files

- `game.lua` — game logic and embedded TIC-80 assets
- `std/strict/init.lua` — Lua strict-variable support used by the game

## Running

Open `game.lua` in TIC-80. The `std/strict/init.lua` file should be available in the TIC-80 filesystem so the game's `require 'std.strict'` call can load it.

From a TIC-80 installation with filesystem support, you can also start TIC-80 with the repository directory mounted and load the game from there.

## Controls

The game uses the TIC-80 controller for movement and shooting.
