# Ratmaid

A stylish bottom-up action shooter where the cleanup is just as important as the killing.

Built in Godot 4.6, this game drops you into a compact, brutal operation inspired by the speed and pressure of Hotline Miami. You play as an operative maid who enters a target location after picking up an intercepted signal, shoot through the room and leave nothing behind.

Made for the Omsk Ludum Dare gathering:
https://ldjam.com/events/ludum-dare/59/$428823/omsk-ludum-dare-gathering-is-here

## Visual Style

A distinctive visual feature of the game is its bottom-up perspective.

## Features

- Two-phase gameplay: eliminate all targets, then clean up the evidence before the SWAT team arrives
- One-hit kills for both player and enemies
- Dual-pistol shooting with alternating muzzles and shell casing ejection
- Burst-fire enemy AI with raycast line-of-sight and NavigationAgent2D pathfinding
- SWAT reinforcements that spawn once the cleanup timer expires
- Corpse carrying and disposal into a trash bin
- Blood mopping with a switchable mop/gun loadout
- Dynamic music system with 5 synchronized stems that cross-fade between game states
- Inverted-color crosshair that renders against any background
- Gamepad and keyboard/mouse support with automatic device detection and per-device button hints
- Localization: Russian and English, switchable in the main menu
- Two difficulty modes with per-difficulty enemy shoot range and fire rate

## Controls

| Action            | Keyboard / Mouse   | Gamepad          |
| ----------------- | ------------------ | ---------------- |
| Move              | WASD / Arrows      | Left stick       |
| Aim               | Mouse              | Right stick      |
| Shoot             | LMB / Space        | RT / R1          |
| Pick up / Drop    | E                  | A / × (Cross)    |
| Mop ↔ Guns        | Tab                | D-pad ↑          |
| Confirm / Continue| Enter / Space      | A / × (Cross)    |
| Cancel            | Esc                | B / ○            |

## Project Structure

```
scenes/       game scenes (menu, level, player, enemies, props, ui)
scripts/      GDScript sources
images/       sprites and UI assets
audio/        music stems and sfx
localization/ RU/EN translation CSV
themes/       UI theme
shaders/      GLSL shaders
```

## Running

Open the project in Godot 4.6 and press F5. On first launch the editor auto-generates `localization/strings.{en,ru}.translation` from the CSV.

Headless smoke-test:
```sh
godot --headless --quit-after 180
```

## Building

Use the export presets defined in `export_presets.cfg`. Requires the matching export templates for Godot 4.6.

## Engine

**Godot 4.6** — Forward Plus renderer, viewport stretch 600×400 @ 2×, Nearest texture filter.

## Credits

- Sensei Chops — *Amen Break* — Standard Licensing, Royalty Free
- All other art, code and design — original
