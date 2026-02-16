extends Entity
class_name Player
var is_my_turn = false

func _ready() -> void:
	speed = 10
	pass

func _start_turn() -> void:
	is_my_turn = true

func _unhandled_input(event):
	if not is_my_turn:
		return
	
	var dir = Vector2i.ZERO
	if event.is_action_pressed("move_up"): dir.y -= 1
	elif event.is_action_pressed("move_down"): dir.y += 1
	elif event.is_action_pressed("move_left"): dir.x -= 1
	elif event.is_action_pressed("move_right"): dir.x += 1
	
	if dir != Vector2i.ZERO:
		is_my_turn = false
		var action = MoveAction.new(self, dir)
		emit_signal("request_action", action)


func end_turn() -> void:
	is_my_turn = false
	set_process_input(false)
	emit_signal("turn_finished")
