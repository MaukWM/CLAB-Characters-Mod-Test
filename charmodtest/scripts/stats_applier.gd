# Applies a character definition's "stats" block to the player.
#
# Runs after the player's own _ready(), so properties the player copied into plain vars at
# construction are already stale by the time we get here. Those are listed in COMPANIONS: the
# definition has to set both, and we warn if only one is present.
extends RefCounted

# property -> other properties that must be set alongside it
const COMPANIONS := {
	"input_speed_cap": ["default_input_speed_cap"],   # player.gd:13, also drives animation speed
	"default_gravity": ["active_gravity"],            # player.gd:24
}


static func apply(player: Node, stats: Dictionary) -> void:
	if stats.is_empty():
		return

	var known := {}
	for prop in player.get_property_list():
		known[prop["name"]] = prop["type"]

	for key in stats:
		var name := str(key)
		if not known.has(name):
			push_warning("CharModTest Stats: player has no property \"%s\" - ignored" % name)
			continue

		var value = _coerce(stats[key], known[name])
		if value == null:
			push_warning("CharModTest Stats: cannot use %s for \"%s\"" % [stats[key], name])
			continue

		player.set(name, value)

		for companion in COMPANIONS.get(name, []):
			if not stats.has(companion):
				push_warning("CharModTest Stats: \"%s\" was set but \"%s\" was not - the player copies it at startup, so it keeps the default" % [name, companion])


# JSON has no Vector3, so [x, y, z] becomes one. Everything else passes through.
static func _coerce(value, type: int):
	if type == TYPE_VECTOR3:
		if value is Array and value.size() == 3:
			return Vector3(float(value[0]), float(value[1]), float(value[2]))
		return null
	if type == TYPE_OBJECT:
		return null   # resources such as Curve cannot come from JSON
	return value
