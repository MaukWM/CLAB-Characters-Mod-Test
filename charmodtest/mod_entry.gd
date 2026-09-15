# CharModTest - Autoload entry point (override.cfg + autoload_prepend)
extends Node

const MOD_DIR = "res://charmodtest/"

var registry: Node


func _init() -> void:
	print("CharModTest: Mod initializing...")


func _ready() -> void:
	registry = Node.new()
	registry.name = "CharacterRegistry"
	registry.set_script(load(MOD_DIR + "scripts/character_registry.gd"))
	add_child(registry)
	registry.scan()
	# TEMP: remove once the picker shows this.
	for id in registry.order:
		print("CharModTest: character '%s' -> %s" % [id, registry.display_name(id)])

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
	print("CharModTest: player ready - %s" % player.name)
