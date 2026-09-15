# Loads portrait.png from a character folder, if it has one.
#
# Loose PNGs must go through the Image API - load() only resolves resources the importer produced,
# which do not exist in the shipped game.
extends RefCounted

const FILE_NAME := "portrait.png"

static var _cache: Dictionary = {}


static func build(id: String, dir: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]

	var path := dir + FILE_NAME
	if not FileAccess.file_exists(path):
		return null

	var image := Image.load_from_file(path)
	if image == null:
		push_warning("CharModTest Portrait: cannot read %s" % path)
		return null

	var texture := ImageTexture.create_from_image(image)
	_cache[id] = texture
	return texture
