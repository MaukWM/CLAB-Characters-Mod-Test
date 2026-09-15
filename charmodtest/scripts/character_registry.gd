# Finds every charmodtest/characters/<id>/character.json and keeps the parsed definitions.
#
# DirAccess on a res:// path only sees the pck in an exported game, and the mod ships as loose
# files, so the folder is listed through its real filesystem path instead. That works both in the
# exported game (res:// = the exe folder) and in the decomp project (res:// = the project folder).
extends Node

const CHAR_DIR := "res://charmodtest/characters/"

var characters: Dictionary = {}   # id -> definition, with "id" and "dir" added
var order: Array[String] = []     # display order, cirno first


func scan() -> void:
	characters.clear()
	order.clear()

	var ids: Array[String] = []
	var dir := DirAccess.open(ProjectSettings.globalize_path(CHAR_DIR))
	if dir == null:
		push_error("CharModTest Registry: cannot list %s" % CHAR_DIR)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			ids.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	ids.sort()

	for id in ids:
		var def = _read_json(CHAR_DIR + id + "/character.json")
		if def is Dictionary:
			def["id"] = id
			def["dir"] = CHAR_DIR + id + "/"
			characters[id] = def
			order.append(id)
		else:
			push_warning("CharModTest Registry: skipping %s, no valid character.json" % id)

	if order.has("cirno"):
		order.erase("cirno")
		order.push_front("cirno")


func has_character(id: String) -> bool:
	return characters.has(id)


# Returns {} for an unknown id so a bad selection never crashes the game, but says so loudly:
# push_error shows red in the debugger and breaks on error in the editor.
func get_character(id: String) -> Dictionary:
	if not characters.has(id):
		push_error("CharModTest Registry: no character '%s' (have: %s)" % [id, ", ".join(order)])
		return {}
	return characters[id]


func display_name(id: String) -> String:
	return str(get_character(id).get("display_name", id))


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_warning("CharModTest Registry: JSON error in %s" % path)
	return parsed
