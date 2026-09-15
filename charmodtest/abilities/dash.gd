# Dash: fires the player forwards.
#
# config keys, on top of the ones ability.gd understands:
#   speed  how fast the dash launches   (default 26)
#   lift   upward kick added to it      (default 4)
extends "res://charmodtest/abilities/ability.gd"


func activate() -> void:
	if not can_activate():
		return

	var direction: Vector3 = player.move_direction_of_frame
	if direction.length() < 0.1:
		# Not steering, so use the way the model is facing.
		direction = player.facing()
	direction = Vector3(direction.x, 0.0, direction.z).normalized()
	if direction == Vector3.ZERO:
		return

	var speed := float(config.get("speed", 26.0))
	var lift := float(config.get("lift", 4.0))
	player.velocity = Vector3(direction.x * speed, player.velocity.y + lift, direction.z * speed)
	start_cooldown()
