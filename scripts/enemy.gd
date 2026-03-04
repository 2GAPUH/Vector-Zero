extends Entity
class_name Enemy

# === ВРАГ ===


func _ready() -> void:
	super._ready()
	
	# Добавляем способности врагу
	add_ability(MoveAbility.new())
	add_ability(DashAbility.new())
	add_ability(AttackAbility.new())
	
	# Создаём AI контроллер
	controller = EnemyAIController.new(self)


# === НАЧАТЬ ХОД ВРАГА ===
func _start_turn() -> void:
	super._start_turn()
	
	if controller == null:
		emit_signal("turn_finished")
		return
	
	# Получаем действие от AI
	var action: Action = controller.get_next_action()
	
	if action != null:
		# Выполняем действие
		emit_signal("request_action", action)
	
	# Завершаем ход (у врага одно действие)
	emit_signal("turn_finished")
