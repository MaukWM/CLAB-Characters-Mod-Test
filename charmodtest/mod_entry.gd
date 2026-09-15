# CharModTest — Autoload entry point (override.cfg + autoload_prepend)
extends Node

const MOD_DIR = "res://charmodtest/"

func _init() -> void:
	print("CharModTest: Mod initializing...")

func _ready() -> void:
	print("CharModTest: All systems ready.")
