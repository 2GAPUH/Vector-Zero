extends Entity
class_name Enemy

# === КОНСТАНТЫ ===
const MOVE_RANGE: int = 2
const DASH_RANGE: int = 6
const ATTACK_RANGE: int = 1


func _ready() -> void:
	super._ready()
	_initialize_abilities()
	# Создаём AI контроллер
	controller = AIController.new(self)


# Инициализация способностей врага
func _initialize_abilities() -> void:
	# Базовое перемещение (бесплатное)
	var move_ability: MoveAbility = MoveAbility.new()
	move_ability.ability_name = "Перемещение"
	move_ability.ap_cost = 0
	move_ability.range = MOVE_RANGE
	add_ability(move_ability)
	
	# Рывок (стоит 1 AP)
	var dash_ability: DashAbility = DashAbility.new()
	dash_ability.ability_name = "Рывок"
	dash_ability.ap_cost = 1
	dash_ability.range = DASH_RANGE
	add_ability(dash_ability)
	
	# Атака (стоит 1 AP)
	var attack_ability: AttackAbility = AttackAbility.new()
	attack_ability.ability_name = "Атака"
	attack_ability.ap_cost = 1
	attack_ability.range = ATTACK_RANGE
	attack_ability.damage = base_damage
	add_ability(attack_ability)


# Начать ход врага
func _start_turn() -> void:
	super._start_turn()
	
	if controller == null:
		emit_signal("turn_finished")
		return
	
	# Запускаем AI для выполнения действий
	_execute_ai_turn()


# Выполнить ход AI
func _execute_ai_turn() -> void:
	# AI может выполнять несколько действий, пока есть AP
	while current_ap > 0:
		var action: Action = controller.get_next_action()
		
		if action == null:
			break
		
		emit_signal("request_action", action)
		
		# Небольшая задержка между действиями
		await get_tree().create_timer(0.3).timeout
	
	# Завершаем ход
	emit_signal("turn_finished")


# === ИНФОРМАЦИЯ ===

func get_display_name() -> String:
	return "Враг"
