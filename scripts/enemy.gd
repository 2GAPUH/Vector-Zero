extends Entity
class_name Enemy



func _start_turn() -> void:
	move_ai()

func move_ai() -> void:
	if not current_level:
		emit_signal("turn_finished")
		print("Level not initialized")
		return
	
	var target_pos: Vector2i = current_level.get_player_position()
	
	var direction: Vector2i = target_pos - tile_position
	
	var move_dir: Vector2i = Vector2i.ZERO
	
	if direction.x != 0:
		move_dir.x = sign(direction.x)
	elif direction.y != 0:
		move_dir.y = sign(direction.y)
	
	if move_dir != Vector2i.ZERO:
		print("Move requsted")
		var action = MoveAction.new(self, move_dir)
		emit_signal("request_action", action)
	else:
		print("Zero movement")
		emit_signal("turn_finished")
