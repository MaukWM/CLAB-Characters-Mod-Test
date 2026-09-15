# Adds the character picker to the title menu whenever it appears.
#
# The title menu is created and freed as the game moves between screens, so this watches for it
# rather than injecting once.
extends Node

const PickerScene := preload("res://charmodtest/ui/character_picker.tscn")

var _registry: Node
var _config: Node
var _injected := false


func setup(registry: Node, config: Node) -> void:
	_registry = registry
	_config = config


func _process(_delta: float) -> void:
	var menu := _find_title_menu()
	if menu == null:
		_injected = false
		return
	if _injected:
		return
	_inject(menu)
	_injected = true


func _find_title_menu() -> Node:
	if not is_instance_valid(Globals.MENU_NODE):
		return null
	for child in Globals.MENU_NODE.get_children():
		if child.name == "TitleMenu":
			return child
	return null


func _inject(menu: Node) -> void:
	var picker: Control = PickerScene.instantiate()
	picker.setup(_registry, _config)
	menu.add_child(picker)
	picker.wire_focus(menu)
