# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Two self-contained browser games, each a single HTML file with all CSS and JS inline. No build tools, no dependencies, no server needed — open the file directly in a browser to run.

- **bengo.html** — 4-level retro 2D platformer (the main project)
- **tictactoe.html** — two-player Tic Tac Toe with score tracking

## Running the games

Open the file directly in a browser. On Windows: `start "" "bengo.html"` or `start "" "tictactoe.html"`.

**Bengo dev shortcut:** press `L` in-game to jump straight to level 4 (boss level) for testing.

## Git workflow

After every meaningful change: commit with a clean message and push to `https://github.com/tic505/bengo-game`. Always keep local and remote in sync.

## Bengo architecture

Everything lives in one `<script>` block. The main systems:

### Game loop
`loop()` → `requestAnimationFrame`. Dispatches to `updateGame()` + `drawWorld()` when state is `"playing"`, or `drawScreen()` for `menu / gameover / win`.

### State machine
`game.state`: `"menu"` → `"playing"` → `"gameover"` or `"win"`. Enter/Exit via `loadLevel(index)` and key handlers.

### Level format
`LEVELS` is an array of string arrays. Each character maps to a tile or entity spawn:
- `#` → stone wall tile
- `P` → player spawn (sets `player.x/y`)
- `E` → grunt enemy spawn
- `B` → boss (KLANAC) spawn
- `F` → goal flag (reaching it with `kills >= requiredKills` advances the level)

`REQUIRED_KILLS` parallel array sets the kill threshold per level. Level 4 (index 3) also sets `game.bossIntro = 120` for a cutscene pause.

### Physics
`moveAndCollide(entity)` handles all movement and AABB tile collision for both player and enemies. Gravity constant `0.8`, max fall `14`. Player jump impulse `-14`.

### Combat
- **Sword** (`J`/`Z`): pushes an attack hitbox rect into `game.attacks[]` for 6 frames.
- **Power-up** (`K`/`X`, requires `player.power >= 100`): fires a projectile into `game.projectiles[]` that passes through all enemies (tracked via `hits: new Set()`), one-shots grunts, deals 50 damage to the boss on level 4.
- **Enemy projectiles** live in `game.enemyProjectiles[]`, fired by the boss on a `shootCd` / `shootWindup` timer.
- Grunt kill: `+34` power. Boss kill: `+40` power. Power caps at 100.
- Stomp (player falling onto enemy head) deals the same damage as a sword hit.

### Drawing functions
Each entity type has its own draw function called from `drawWorld()`:
- `drawPlayer()` — armored warrior with directional facing, sword raise on attack, hurt flash
- `drawGrunt(e)` — octopus-cat: tabby cat head with cat ears/eyes/whiskers on top of a purple octopus body with tentacles
- `drawBoss(e)` — KLANAC: split vertically, left half human warrior (red eye, dark armor, sword), right half cat (yellow slit eye, ear, fur, claws). Glows gold when `shootWindup > 0`.

### Audio
Web Audio API only, no external files. `beep(type, freq, dur)` for tonal sounds, `noise(dur)` for white noise. `sfx(name)` maps named events to sounds.
