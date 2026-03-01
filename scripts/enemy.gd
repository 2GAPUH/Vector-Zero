extends Entity
class_name Enemy

func _ready() -> void:
	controller = ChaseController.new(self)

func _start_turn() -> void:
	if controller == null:
		emit_signal("turn_finished")
		return
	
	var action: Action = controller.get_action()
	
	if action != null:
		emit_signal("request_action", action)
	else:
		emit_signal("turn_finished")
