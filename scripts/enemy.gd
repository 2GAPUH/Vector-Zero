extends Entity
class_name Enemy


func _ready() -> void:
	# Создаём контроллер преследования
	controller = ChaseController.new(self)


# Начать ход врага
func _start_turn() -> void:
	if controller == null:
		emit_signal("turn_finished")
		return
	
	# Получаем действие от контроллера
	var action: Action = controller.get_next_action()
	
	if action != null:
		emit_signal("request_action", action)
	
	# Завершаем ход (у врага одно действие за ход)
	emit_signal("turn_finished")
