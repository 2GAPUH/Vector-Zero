class_name AttackAbility
extends Ability

# === СПОСОБНОСТЬ: АТАКА ===
# Стоимость: 1 AP
# Атака в 4 стороны (вплотную)
# Урон: 1 HP


# Базовый урон
const BASE_DAMAGE: int = 1

# 4 направления (стороны света)
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1),   # UP
	Vector2i(0, 1),    # DOWN
	Vector2i(-1, 0),   # LEFT
	Vector2i(1, 0)     # RIGHT
]


func _init() -> void:
	name = "Атака"
	description = "Атака в соседнюю клетку. 1 урон. Стоимость: 1 AP"
	cost = 1


# === МОЖНО ЛИ ИСПОЛЬЗОВАТЬ ===
func can_use() -> bool:
	if not super.can_use():
		return false
	
	# Должна быть хотя бы одна цель рядом
	return get_valid_targets().size() > 0


# === ПОЛУЧИТЬ ВАЛИДНЫЕ ЦЕЛИ ===
func get_valid_targets() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	
	if entity == null or entity.current_level == null:
		return result
	
	for dir: Vector2i in DIRECTIONS:
		var target_pos: Vector2i = entity.tile_position + dir
		var target_entity: Entity = entity.current_level.get_entity_at(target_pos)
		
		# Можно атаковать живые сущности и препятствия
		if target_entity != null:
			# Живые сущности (враги, игрок)
			if target_entity.is_alive and target_entity != entity:
				result.append(target_pos)
			# Препятствия (включая трупы)
			elif target_entity is Obstacle:
				result.append(target_pos)
	
	return result


# === ВЫПОЛНИТЬ АТАКУ ===
func execute(target: Variant) -> bool:
	if not target is Vector2i:
		return false
	
	if not is_valid_target(target):
		return false
	
	var target_entity: Entity = entity.current_level.get_entity_at(target)
	if target_entity == null:
		return false
	
	# Тратим AP
	entity.spend_ap(cost)
	
	# Наносим урон
	target_entity.take_damage(BASE_DAMAGE, entity)
	
	# Создаём действие атаки (для истории)
	var action: AttackAction = AttackAction.new(entity, target_entity, BASE_DAMAGE, target)
	entity.emit_signal("request_action", action)
	
	return true


# === ДАЛЬНОСТЬ ===
func get_range() -> int:
	return 1


# === ЦВЕТ ПОДСВЕТКИ ===
func get_highlight_color() -> Color:
	return Color(1.0, 0.2, 0.2, 0.5)  # Красный
