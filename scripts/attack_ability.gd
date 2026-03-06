class_name AttackAbility
extends Ability

# 4 направления (стороны света)
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),   # Право
	Vector2i(-1, 0),  # Лево
	Vector2i(0, 1),   # Вниз
	Vector2i(0, -1)   # Вверх
]


func _init() -> void:
	ability_name = "Атака"
	description = "Атаковать соседнюю цель"
	ap_cost = 1
	range = 1
	damage = 1
	target_type = TargetType.DIRECTION


# can_use проверяет только AP (наследуется от Ability)
# Наличие целей проверяется через has_valid_targets


# Получить валидные цели (соседние клетки с врагами или препятствиями)
func get_valid_targets(entity: Entity, level: Level) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var start_pos: Vector2i = entity.tile_position
	
	for dir: Vector2i in DIRECTIONS:
		var target_pos: Vector2i = start_pos + dir
		var target_entity: Entity = level.get_entity_at(target_pos)
		
		# Можно атаковать врагов и препятствия
		if target_entity != null:
			if target_entity is Obstacle:
				result.append(target_pos)
			elif entity is Hero and target_entity is Enemy:
				result.append(target_pos)
			elif entity is Enemy and target_entity is Hero:
				result.append(target_pos)
	
	return result


# Создать действие атаки
func create_action(entity: Entity, target: Variant, level: Level) -> Action:
	if not target is Vector2i:
		return null
	
	var target_pos: Vector2i = target as Vector2i
	
	# Проверяем, что цель соседняя
	var diff: Vector2i = target_pos - entity.tile_position
	if abs(diff.x) + abs(diff.y) != 1:
		return null
	
	# Получаем цель
	var target_entity: Entity = level.get_entity_at(target_pos)
	
	if target_entity == null:
		return null
	
	# Проверяем AP
	if not entity.has_ap(ap_cost):
		return null
	
	# Тратим AP
	entity.spend_ap(ap_cost)
	
	# Создаём действие атаки
	return AttackAction.new(entity, target_entity, damage)
