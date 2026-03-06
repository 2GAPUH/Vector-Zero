class_name DashAbility
extends Ability


func _init() -> void:
	ability_name = "Рывок"
	description = "Утроить максимальный запас движения. Мгновенное применение."
	ap_cost = 1
	range = 0
	target_type = TargetType.NONE


# Рывок не требует выбора цели
func get_valid_targets(_entity: Entity, _level: Level) -> Array[Vector2i]:
	return []


# Проверить, можно ли использовать способность
func can_use(entity: Entity, _level: Level) -> bool:
	# Базовая проверка AP
	if not entity.has_ap(ap_cost):
		return false
	
	# Только живые сущности
	if not entity.is_alive:
		return false
	
	return true


# Создать действие рывка (мгновенное, без цели)
func create_action(entity: Entity, _target: Variant, _level: Level) -> Action:
	if not entity.has_ap(ap_cost):
		return null
	
	# Тратим AP
	entity.spend_ap(ap_cost)
	
	# Применяем эффект рывка - утраиваем МАКСИМАЛЬНЫЙ запас движения
	entity.apply_dash_boost()
	
	# Создаём действие рывка (пустое, только для записи в историю)
	var action: DashAction = DashAction.new(entity)
	return action
