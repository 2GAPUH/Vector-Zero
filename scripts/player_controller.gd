class_name PlayerController
extends Controller

var _pending_direction: Vector2i = Vector2i.ZERO
var _pending_target: Vector2i = Vector2i.ZERO
var _has_pending_input: bool = false

func get_intent() -> Intent:
	if _has_pending_input and _pending_direction != Vector2i.ZERO:
		return MoveIntent.new(entity, _pending_direction)
	return null

func get_action() -> Action:
	if not _has_pending_input:
		return null
	
	var action: Action = null
	
	if _pending_direction != Vector2i.ZERO:
		action = MoveAction.new(entity, _pending_direction)
	
	_clear_input()
	return action

func set_input_direction(direction: Vector2i) -> void:
	if direction != Vector2i.ZERO:
		_pending_direction = direction
		_has_pending_input = true

func set_input_target(target_pos: Vector2i) -> void:
	var direction: Vector2i = target_pos - entity.tile_position
	
	if direction != Vector2i.ZERO:
		_pending_direction = _normalize_direction(direction)
		_has_pending_input = true

func has_pending_input() -> bool:
	return _has_pending_input

func _clear_input() -> void:
	_pending_direction = Vector2i.ZERO
	_pending_target = Vector2i.ZERO
	_has_pending_input = false

func _normalize_direction(dir: Vector2i) -> Vector2i:
	var result: Vector2i = Vector2i.ZERO
	
	if abs(dir.x) >= abs(dir.y):
		result.x = sign(dir.x)
	else:
		result.y = sign(dir.y)
	
	return result
