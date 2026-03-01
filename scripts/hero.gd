extends Entity
class_name Hero

# Флаг: сейчас ход героя
var _is_my_turn: bool = false


func _ready() -> void:
	speed = 10


# Начать ход героя
func _start_turn() -> void:
	_is_my_turn = true


# Обработка ввода
func _unhandled_input(event: InputEvent) -> void:
	if not _is_my_turn:
		return
	
	_handle_keyboard_input(event)
	_handle_mouse_input(event)


# Обработка клавиатуры
func _handle_keyboard_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	
	if not event.is_pressed() or event.is_echo():
		return
	
	var dir: Vector2i = Vector2i.ZERO
	
	if event.is_action_pressed("move_up"):
		dir.y -= 1
	elif event.is_action_pressed("move_down"):
		dir.y += 1
	elif event.is_action_pressed("move_left"):
		dir.x -= 1
	elif event.is_action_pressed("move_right"):
		dir.x += 1
	
	if dir != Vector2i.ZERO:
		_execute_move(dir)


# Обработка мыши
func _handle_mouse_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	
	if not event.is_pressed():
		return
	
	if event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2i = current_level.local_to_tile(event.position)
		var direction: Vector2i = click_pos - tile_position
		
		# Нормализуем направление (один шаг)
		var move_dir: Vector2i = _normalize_direction(direction)
		
		if move_dir != Vector2i.ZERO:
			_execute_move(move_dir)


# Нормализовать направление до одного шага
func _normalize_direction(dir: Vector2i) -> Vector2i:
	var result: Vector2i = Vector2i.ZERO
	
	if abs(dir.x) >= abs(dir.y):
		result.x = sign(dir.x)
	else:
		result.y = sign(dir.y)
	
	return result


# Выполнить перемещение (ход НЕ завершается автоматически)
func _execute_move(direction: Vector2i) -> void:
	var action: MoveAction = MoveAction.new(self, direction)
	emit_signal("request_action", action)


# Завершить ход (вызывается по кнопке)
func end_turn() -> void:
	_is_my_turn = false
	emit_signal("turn_finished")


# Проверить, сейчас ли ход этого героя
func is_my_turn() -> bool:
	return _is_my_turn
