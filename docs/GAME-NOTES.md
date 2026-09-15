# Game internals the mod depends on

THIS FILE IS NOT VETTED YET

Verified against the decompiled project. Line numbers are from `scenes/player/player/player.gd`
unless stated otherwise. If a game patch breaks the mod, start here.

## How the mod gets in

No game file is copied or altered. Three mechanisms:

| | |
| --- | --- |
| **Subclass** | `player_modded.gd` does `extends "res://scenes/player/player/player.gd"`. A loose script can extend the pck's tokenized script. `super()` runs the game's own logic. |
| **Scene inheritance** | `player_modded.tscn` instances `res://scenes/player/player/player.tscn` and swaps the script. It references game content, never contains it. |
| **Pointer swap** | `main.gd:12` declares `var player_scene = preload(".../player.tscn")` and `main.gd:342` does `player_scene.instantiate()`. The mod reassigns that property at runtime. |

`Globals.MAIN_NODE` is assigned in `main.gd:77`, inside `main.gd`'s own `_ready`. Autoloads are
created before the main scene, so it does not exist when the mod's `_ready` runs - `mod_entry.gd`
awaits it.

## Ability unlocks

`player.gd:1079-1092` unlocks abilities by energy portions collected:

| portions | unlocks | flag |
| --- | --- | --- |
| 1 | float | `float_ability_unlocked` |
| 2 | flutter jump | `jump_extend_ability_unlocked` |
| 3 | ice platform | `ice_platform_ability_unlocked` |

The flags are set back to `true` on pickup, which is why disabling one means holding it off every
frame rather than setting it once.

Trigger points: float is inline at lines 445, 463, 480, 497, 517 (no method to override).
`check_flutter_jump()` is at 977 and gates on its flag internally. `check_ice_platform()` is at 988
and is gated by its caller (447, 465, 482, 519, 544).

## Properties copied at construction

Two exported properties are read into plain vars when the player is built, so setting the export
after `_ready` leaves the copy stale:

| export | copy | why it matters |
| --- | --- | --- |
| `input_speed_cap` | `default_input_speed_cap` (line 13) | line 643 uses the copy for animation speed |
| `default_gravity` | `active_gravity` (line 24) | the copy is what gravity actually reads |

`stats_applier.gd` warns when one is set without the other.

## Loose files the shipped game can read

The shipped game has **no importer**. Anything that only exists after Godot imports it
(`.godot/imported/*`, `.import`, `.ctex`) is absent for players.

| type | how to load it |
| --- | --- |
| `.gd` | `load()`, `extends "res://..."` |
| `.png .jpg .webp` | `Image.load_from_file()` - **not** `load()` |
| `.glb .gltf` | `GLTFDocument.append_from_file()`; editor import settings are ignored |
| `.tscn .tres` (text) | `load()`, only if every `ext_resource` is a pck resource or another loose text/gd file |
| `.json .cfg` | `FileAccess` / `JSON` / `ConfigFile` |

`DirAccess` on a `res://` path only sees the pck, so listing a loose mod folder needs
`ProjectSettings.globalize_path()` first. `character_registry.gd` depends on this.

## Assets referenced by the mod

Referenced by `res://` path at runtime, never copied into the zip:

- `res://sprites/ui/selector.png` - the arrow graphic, 256x64. The triangles are the nine-patch
  margins: `Rect2(0, 0, 66, 64)` points right, `Rect2(190, 0, 66, 64)` points left.
- `res://theme_stuff/themes/UITheme.tres` - the menu theme.
- `res://audio/SoundEffect.gd` - looked up by name so a rename degrades to silence, not an error.

`Globals.MENU_NODE` holds the menus; the title screen is the child named `TitleMenu`, and
`%ButtonStart` inside it is used for controller focus.

## Living next to Lifters

Godot reads one `override.cfg` at the game root, so both mods share it and ours lists both
autoloads. Lifters respaces the title and Options button columns with hardcoded anchors, so this mod
puts its picker outside those columns.
