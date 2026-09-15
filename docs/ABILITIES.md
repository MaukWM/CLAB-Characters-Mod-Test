# Abilities

THIS FILE IS NOT VETTED YET

An ability is a script in `charmodtest/abilities/` named in a character's `character.json`. It is a
Node parented to the player, so it ticks with the player and is freed with it.

```json
"abilities": {
	"dash": { "key": "K", "speed": 30.0, "cooldown": 0.5 }
}
```

The key is the file name: `"dash"` loads `charmodtest/abilities/dash.gd`.

## Writing one

Extend `ability.gd` and implement `activate()`. Everything else - triggering, cooldown, gating, key
binding - is handled by the base.

```gdscript
extends "res://charmodtest/abilities/ability.gd"

func activate() -> void:
	if not can_activate():
		return
	player.velocity.y = 30.0
	start_cooldown()
```

Config keys every ability understands:

| key | |
| --- | --- |
| `key` | key that triggers it, by name. Required unless `replaces` is set |
| `replaces` | take over one of the game's abilities instead of using a key |
| `cooldown` | seconds before it can fire again (default 0) |
| `unlock_at_power` | power needed before it works (default 0, always on) |

Anything else in the block is the ability's own; read it with `config.get("name", default)`.

## Adding vs replacing

**Adding** is the default and needs no knowledge of the game: give it a `key` and the base registers
its own `InputMap` action at runtime, named after the ability so two never collide.

**Replacing** takes over one of the game's buttons. The slots:

| slot | button | gate |
| --- | --- | --- |
| `flutter_jump` | SPECIAL_2 | inside `check_flutter_jump()`, so the ability works from spawn |
| `ice_platform` | SPECIAL | in the caller, so it only fires once the game unlocks ice platform |
| `float` | - | **cannot be replaced**, only disabled - see below |

Float is entered inline in five places in `player.gd` with no method to override. The other two go
through `check_*` methods that `player_modded.gd` overrides.

## Disabling a game ability

```json
"disable": ["float"]
```

Valid names are the three slots above. The game switches these flags back on as the player picks the
abilities up, so `player_modded.gd` holds them off every frame. There is a one-frame window on the
pickup where the game's own check still runs.

## Where the game knowledge lives

`player_modded.gd` is the only file that knows how the game is wired - which flag belongs to which
slot, which button maps to which check, and how to read the model's facing (`player.facing()`).
Abilities should never reach into the game's nodes directly; if one needs something new, add a
helper there instead.
