class_name DashAction
extends Action

# Запас движения до применения рывка (для отката)
var old_move_budget: int = 0
var old_max_move_budget: int = 0


func _init(actor: Entity) -> void:
	super(actor)
	if actor != null:
		old_move_budget = actor.move_budget
		old_max_move_budget = actor.max_move_budget


# Выполнить рывок (эффект уже применён в DashAbility)
func execute(_level: Level) -> bool:
	# Эффект рывка уже применён в DashAbility.create_action()
	print("DashAction: рывок выполнен")
	return true


# Отменить рывок
func undo(_level: Level) -> void:
	if entity != null:
		# Возвращаем старые значения
		entity.move_budget = old_move_budget
		entity.max_move_budget = old_max_move_budget
		
		# Возвращаем AP
		entity.current_ap += 1
		
		print("DashAction: рывок отменён, бюджет восстановлен: ", entity.move_budget, "/", entity.max_move_budget)
