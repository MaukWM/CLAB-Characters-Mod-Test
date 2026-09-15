# The game's player, extended. The game spawns this instead of its own player, so methods
# here can run before super(), after it, or replace it.
#
# This is the only file that knows how the game's own abilities are wired. Abilities name a slot
# in character.json ("replaces") or a disable ("disable") and never touch game internals.
extends "res://scenes/player/player/player.gd"

# slot name -> the exported flag that switches the game's ability on
const ABILITY_FLAGS := {
	"float": "float_ability_unlocked",
	"flutter_jump": "jump_extend_ability_unlocked",
	"ice_platform": "ice_platform_ability_unlocked",
}

# Set by mod_entry from the character definition.
var mod_abilities: Array[Node] = []
var disabled_abilities: Array = []


func _ready() -> void:
	super()
	# Only mod_entry spawns this scene, so the autoload is present in-game. The guard is for
	# opening this scene directly in the editor.
	var mod := get_node_or_null("/root/CharModTest")
	if mod != null:
		mod.on_player_ready(self)


func _physics_process(delta: float) -> void:
	# The game switches these back on as they are picked up, so they are held off every frame.
	for slot in disabled_abilities:
		var flag: String = ABILITY_FLAGS.get(slot, "")
		if flag.is_empty():
			push_warning("CharModTest: unknown ability to disable: %s" % slot)
		else:
			set(flag, false)
	super(delta)


# The direction the model is facing (this is probs wrong, this is where the player in inputting not model facing). Abilities use this instead of reaching into the game's nodes.
func facing() -> Vector3:
	return _skin.global_basis.z


# The game calls these when SPECIAL / SPECIAL_2 are pressed. An ability can take the button over,
# in which case the game's own ability never triggers.
func check_ice_platform() -> bool:
	var ability := _ability_replacing("ice_platform")
	if ability == null:
		return super()
	if Input.is_action_just_pressed("SPECIAL"):
		ability.activate()
	return false


func check_flutter_jump() -> bool:
	var ability := _ability_replacing("flutter_jump")
	if ability == null:
		return super()
	if Input.is_action_just_pressed("SPECIAL_2"):
		ability.activate()
	return false


func _ability_replacing(slot: String) -> Node:
	for ability in mod_abilities:
		if ability.replaces(slot):
			return ability
	return null
