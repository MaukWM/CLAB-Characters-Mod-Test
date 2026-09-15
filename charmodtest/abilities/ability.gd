# Base class for a character ability.
#
# An ability is a Node parented to the player, so it ticks with it and is freed with it. Subclasses
# implement activate(); triggering, cooldown and gating are handled here.
#
# config keys understood by every ability:
#   key             key that triggers it, by name - required unless "replaces" is set
#   replaces        take over one of the game's abilities instead of using a key
#   cooldown        seconds before it can fire again     (default 0)
#   unlock_at_power power needed before it works         (default 0, always on)
extends Node

var player: Node          # the modded player this ability belongs to
var config: Dictionary    # the ability's block from character.json

var _cooldown_left := 0.0


func setup(owner_player: Node, ability_config: Dictionary) -> void:
	player = owner_player
	config = ability_config
	if needs_own_key():
		_bind_action()


# Derived from the node name, which mod_entry sets to the ability's name, so two abilities on the
# same character never share an action.
func action_name() -> String:
	return "CHARMOD_" + str(name).to_upper()


# Which of the game's own abilities this one takes over, if any. The slots and their buttons are
# defined by player_modded.gd.
func replaces(slot: String) -> bool:
	return str(config.get("replaces", "")) == slot


func needs_own_key() -> bool:
	return str(config.get("replaces", "")).is_empty()


# Guards shared by every ability. Subclasses call this first in activate().
func can_activate() -> bool:
	if player == null or _cooldown_left > 0.0 or player.disable_input:
		return false
	var required := float(config.get("unlock_at_power", 0.0))
	if required <= 0.0:
		return true
	if not is_instance_valid(Globals.MAIN_NODE):
		return false
	return Globals.MAIN_NODE.game_power >= required


func start_cooldown() -> void:
	_cooldown_left = float(config.get("cooldown", 0.0))


# What the ability does. Overridden by each ability.
func activate() -> void:
	pass


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	if not needs_own_key():
		return
	var action := action_name()
	if InputMap.has_action(action) and Input.is_action_just_pressed(action):
		activate()


# The game has no spare actions, so each ability registers its own. InputMap is writable at
# runtime, in the shipped game too.
func _bind_action() -> void:
	var key_name := str(config.get("key", ""))
	if key_name.is_empty():
		push_warning("CharModTest: ability %s has neither \"key\" nor \"replaces\"" % name)
		return
	var keycode := OS.find_keycode_from_string(key_name)
	if keycode == KEY_NONE:
		push_warning("CharModTest: ability %s has unknown key %s" % [name, key_name])
		return
	var action := action_name()
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)
