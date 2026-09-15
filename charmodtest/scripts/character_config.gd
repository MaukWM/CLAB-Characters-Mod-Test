# Which character is selected, remembered between launches.
# Saved under user:// - res:// is read-only in the shipped game.
extends Node

signal character_changed(id: String)

const CONFIG_DIR := "user://charmodtest/"
const CONFIG_PATH := CONFIG_DIR + "config.cfg"
const DEFAULT_ID := "cirno"

var _registry: Node
var _selected: String = DEFAULT_ID


func setup(registry: Node) -> void:
	_registry = registry
	_load()


func get_selected() -> String:
	return _selected


func select(id: String) -> void:
	if id == _selected:
		return
	if not _registry.has_character(id):
		push_warning("CharModTest Config: unknown character %s, keeping %s" % [id, _selected])
		return
	_selected = id
	_save()
	character_changed.emit(_selected)


# step is +1 / -1; wraps around the registry order.
func cycle(step: int) -> void:
	var order: Array = _registry.order
	if order.is_empty():
		return
	var i := order.find(_selected)
	if i < 0:
		i = 0
	select(order[posmod(i + step, order.size())])


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	var saved := str(cfg.get_value("character", "selected", DEFAULT_ID))
	# The saved character may have been removed since it was written.
	if _registry.has_character(saved):
		_selected = saved
	else:
		push_warning("CharModTest Config: saved character %s does not exist, using %s" % [saved, DEFAULT_ID])


func _save() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CONFIG_DIR))
	var cfg := ConfigFile.new()
	cfg.set_value("character", "selected", _selected)
	if cfg.save(CONFIG_PATH) != OK:
		push_warning("CharModTest Config: could not write %s" % CONFIG_PATH)
