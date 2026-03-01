extends Entity
class_name Player

var _is_my_turn: bool = false

func _ready() -> void:
	speed = 10
	controller = PlayerController.new(self)

func _start_turn() -> void:
	_is_my_turn = true

func _unhandled_input(event: InputEvent) -> void:
	if not _is_my_turn:
		return
	
	_handle_keyboard_input(event)
	_handle_mouse_input(event)
	
	if controller.has_pending_input():
		_execute_pending_action()

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
		controller.set_input_direction(dir)

func _handle_mouse_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	
	if not event.is_pressed():
		return
	
	if event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2i = current_level.local_to_tile(event.position)
		controller.set_input_target(click_pos)

func _execute_pending_action() -> void:
	_is_my_turn = false
	
	var action: Action = controller.get_action()
	
	if action != null:
		emit_signal("request_action", action)
	else:
		emit_signal("turn_finished")

func end_turn() -> void:
	_is_my_turn = false
	emit_signal("turn_finished")
