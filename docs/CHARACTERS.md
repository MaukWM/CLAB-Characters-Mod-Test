# Adding a character

A character is a folder under `charmodtest/characters/` containing `character.json`. No code needed.
Copy `characters/_example/` (folders starting with `_` are skipped by the registry), rename it, and
edit. The folder name is the character's id.

```
charmodtest/characters/marisa/character.json
```

```json
{
	"display_name": "Marisa",
	"stats": {
		"jump_impulse_immediate": 21.0
	}
}
```

Every key is optional. An empty `{}` plays exactly like Cirno.

## portrait.png

A `portrait.png` next to `character.json` is shown in the title-screen picker. 64x64 is the size the
existing ones use. If this is not set a character will show nothing (there is no default icon).

## stats

Any exported property on the player. Values are set after the player finishes its own setup.

- numbers and `true` / `false` pass through as-is
- `default_gravity` is a vector, written `[x, y, z]`
- `float_damp_curve` is a `Curve` resource and **cannot** be set from JSON
- an unknown property name logs a warning and is ignored, so check the Output panel after editing

### Set these together

Two properties are copied into plain variables when the player is created, so setting only one leaves
the copy at Cirno's value. Set both, or you get a character that moves at the new speed with the old
animation timing. The mod warns if you set one without the other.

| if you set | also set |
| --- | --- |
| `input_speed_cap` | `default_input_speed_cap` |
| `default_gravity` | `active_gravity` |

### Available properties

**Movement** — `input_speed_cap` `base_acceleration` `air_acceleration`
`base_acceleration_max_speed_mult` `default_gravity` `terminal_gravity` `ground_friction`
`default_ground_snap` `tumble_ground_snap` `land_velocity_mult`

**Skin** — `falling_anim_threshold` `walk_anim_threshold`

**Jump** — `jump_impulse_immediate` `jump_impulse_extend_immediate` `jump_impulse_extend`
`jump_extend_min_duration` `coyote_time` `jump_dust_time` `jump_extend_ability_unlocked`

**Float** — `float_acceleration` `float_target_gravity` `float_gravity_mult` `float_damp_curve_time`
`float_ability_unlocked`

**IcePlatform** — `ice_platform_ability_unlocked` `ice_platform_jump_velocity` `ice_platform_delay`
`ice_platform_yoffset` `ice_platform_energy_cost`

**Skid** — `skid_velocity_loss_threshold` `skid_deacceleration` `skid_bonus_deaccel_opposite_movement`
`run_to_skid_threshold` `skid_min_duration`

**Item Collection Sound** — `item_pitch_increase` `item_pitch_increase_duration` `item_base_pitch`
`item_big_pitch`

**Combo** — `combo_increase`

**Push** — `_push_max_slides` `_push_slide_angle_threshold` `_push_bounce_power_loss_mult`
`_push_decay_ground` `_push_decay_ground_ice` `_push_decay_air` `_push_speedup_threshold`
`_push_velocity_mult_on_slide`

**Energy** — `energy_recovery_pause_time` `energy_runout_penalty_mult` `energy_recovery_amount`
`energy_float_cost` `energy_extend_jump_cost` `energy_extend_jump_cost_init`

**Tumble Dust** — `tumble_dust_min_scale` `tumble_dust_max_scale`

The three `*_ability_unlocked` flags are normally unlocked through progression. Setting one gives the
character that ability from the start, which changes gameplay rather than just feel.

## Testing

Selection takes effect the next time the player spawns, so change it on the title screen. The registry
reads `character.json` once at startup, so editing it needs a game restart.

# Dev note

This file is AI generated, just like basically all the code in the project, but I wanted to mention that I did not vet the list above to the same level I vet everything else in this repo. So there may be errors in it.