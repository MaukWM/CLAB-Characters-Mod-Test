# CharModTest - Autoload entry point (override.cfg + autoload_prepend)
extends Node

const MOD_DIR = "res://charmodtest/"

const StatsApplier := preload("res://charmodtest/scripts/stats_applier.gd")

var registry: Node
var config: Node


func _init() -> void:
	print("CharModTest: Mod initializing...")


func _ready() -> void:
	registry = Node.new()
	registry.name = "CharacterRegistry"
	registry.set_script(load(MOD_DIR + "scripts/character_registry.gd"))
	add_child(registry)
	registry.scan()

	config = Node.new()
	config.name = "CharacterConfig"
	config.set_script(load(MOD_DIR + "scripts/character_config.gd"))
	add_child(config)
	config.setup(registry)
	config.character_changed.connect(_on_character_changed)

	# TEMP: remove once the picker shows this.
	print("CharModTest: characters - %s" % ", ".join(registry.order))
	_print_selection()

	var modded_scene: PackedScene = load(MOD_DIR + "player_modded.tscn")
	if modded_scene == null:
		push_error("CharModTest: could not load player_modded.tscn")
		return

	# main.gd assigns Globals.MAIN_NODE in its own _ready, which runs after autoloads.
	while not is_instance_valid(Globals.MAIN_NODE):
		await get_tree().process_frame

	# main.gd instantiates player_scene when it builds a level.
	Globals.MAIN_NODE.player_scene = modded_scene
	print("CharModTest: All systems ready.")


func on_player_ready(player: Node) -> void:
	var id: String = config.get_selected()
	var def: Dictionary = registry.get_character(id)
	StatsApplier.apply(player, def.get("stats", {}))
	print("CharModTest: player ready as %s" % registry.display_name(id))


func _on_character_changed(_id: String) -> void:
	_print_selection()


# TEMP: [ and ] cycle the selection until the picker exists. Function keys are avoided because
# the editor claims several of them while the game is running.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_BRACKETRIGHT:
		config.cycle(1)
	elif event.keycode == KEY_BRACKETLEFT:
		config.cycle(-1)


# TEMP
func _print_selection() -> void:
	var id: String = config.get_selected()
	print("CharModTest: selected '%s' (%s)" % [id, registry.display_name(id)])
