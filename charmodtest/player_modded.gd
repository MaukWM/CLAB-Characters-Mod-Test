# The game's player, extended. The game spawns this instead of its own player, so methods
# here can run before super(), after it, or replace it.
extends "res://scenes/player/player/player.gd"


func _ready() -> void:
	super()
	# Only mod_entry spawns this scene, so the autoload is present in-game. The guard is for
	# opening this scene directly in the editor.
	var mod := get_node_or_null("/root/CharModTest")
	if mod != null:
		mod.on_player_ready(self)
