class_name ChaseController
extends Controller

func get_intent() -> Intent:
	var move_dir: Vector2i = _calculate_move_direction()
	
	if move_dir != Vector2i.ZERO:
		return MoveIntent.new(entity, move_dir)
	return null

func get_action() -> Action:
	var move_dir: Vector2i = _calculate_move_direction()
	
	if move_dir != Vector2i.ZERO:
		return MoveAction.new(entity, move_dir)
	return null

func _calculate_move_direction() -> Vector2i:
	if not entity.current_level:
		return Vector2i.ZERO
	
	var target_pos: Vector2i = entity.current_level.get_player_position()
	var direction: Vector2i = target_pos - entity.tile_position
	
	var move_dir: Vector2i = Vector2i.ZERO
	
	if direction.x != 0:
		move_dir.x = sign(direction.x)
	elif direction.y != 0:
		move_dir.y = sign(direction.y)
	
	return move_dir
