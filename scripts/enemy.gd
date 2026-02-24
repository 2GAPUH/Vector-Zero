extends Entity
class_name Enemy

func _start_turn() -> void:
	var move_dir: Vector2i = _calculate_move_direction()
	
	if move_dir != Vector2i.ZERO:
		var action: MoveAction = MoveAction.new(self, move_dir)
		emit_signal("request_action", action)
	else:
		emit_signal("turn_finished")

func get_intent() -> Intent:
	var move_dir: Vector2i = _calculate_move_direction()
	
	if move_dir != Vector2i.ZERO:
		return MoveIntent.new(self, move_dir)
	return null

func _calculate_move_direction() -> Vector2i:
	if not current_level:
		return Vector2i.ZERO
	
	var target_pos: Vector2i = current_level.get_player_position()
	var direction: Vector2i = target_pos - tile_position
	
	var move_dir: Vector2i = Vector2i.ZERO
	
	if direction.x != 0:
		move_dir.x = sign(direction.x)
	elif direction.y != 0:
		move_dir.y = sign(direction.y)
	
	return move_dir
