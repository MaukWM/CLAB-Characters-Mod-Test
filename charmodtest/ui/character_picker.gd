# Title-screen character picker. All layout and styling lives in character_picker.tscn - edit that
# in the editor. This script only fills it with data and reports clicks.
extends Control

const PortraitBuilder := preload("res://charmodtest/ui/portrait_builder.gd")

@onready var _portrait: TextureRect = $Layout/Row/Portrait
@onready var _prev_button: TextureButton = $Layout/Row/PrevButton
@onready var _next_button: TextureButton = $Layout/Row/NextButton

var _registry: Node
var _config: Node


# Called before the node is added to the tree.
func setup(registry: Node, config: Node) -> void:
	_registry = registry
	_config = config


func _ready() -> void:
	_prev_button.pressed.connect(_step.bind(-1))
	_next_button.pressed.connect(_step.bind(1))
	_config.character_changed.connect(_on_character_changed)
	_refresh()


# Lets the arrows be reached with a controller or the arrow keys from the menu column.
func wire_focus(menu: Node) -> void:
	var start: Control = menu.get_node_or_null("%ButtonStart")
	if start == null:
		return
	start.focus_neighbor_left = _next_button.get_path()
	_next_button.focus_neighbor_right = start.get_path()
	_next_button.focus_neighbor_left = _prev_button.get_path()
	_prev_button.focus_neighbor_right = _next_button.get_path()
	_prev_button.focus_neighbor_left = _prev_button.get_path()
	for button in [_prev_button, _next_button]:
		button.focus_neighbor_top = start.get_path()
		button.focus_neighbor_bottom = start.get_path()


func _step(direction: int) -> void:
	_config.cycle(direction)
	_play_change_sound()


func _on_character_changed(_id: String) -> void:
	_refresh()


func _refresh() -> void:
	var id: String = _config.get_selected()
	var def: Dictionary = _registry.get_character(id)
	_portrait.texture = PortraitBuilder.build(id, str(def.get("dir", "")))
	_portrait.tooltip_text = _registry.display_name(id)


# The SoundEffect enum lives in a pck script; look it up by name so a rename in a game patch means
# no sound rather than a script error.
func _play_change_sound() -> void:
	var sound_effect := load("res://audio/SoundEffect.gd")
	if sound_effect == null or not is_instance_valid(Globals.AUDIO_MANAGER):
		return
	var types = sound_effect.get_script_constant_map().get("SOUND_EFFECT_TYPE", null)
	if types is Dictionary and types.has("UI_MENU_CHANGE"):
		Globals.AUDIO_MANAGER.create_audio(types["UI_MENU_CHANGE"])
