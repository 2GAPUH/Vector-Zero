class_name DashAbility
extends Ability

# Путь для рывка
var last_path: Array[Vector2i] = []


func _init() -> void:
	ability_name = "Рывок"
	description = "Быстрый рывок на большое расстояние"
	ap_cost = 1
	range = 6
	target_type = TargetType.TILE


# Получить валидные цели
func get_valid_targets(entity: Entity, level: Level) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var start_pos: Vector2i = entity.tile_position
	
	# Используем A* для поиска достижимых клеток
	result = Pathfinder.get_reachable_tiles(start_pos, level, range)
	
	# Убираем текущую позицию
	result.erase(start_pos)
	
	return result


# Создать действие рывка
func create_action(entity: Entity, target: Variant, level: Level) -> Action:
	if not target is Vector2i:
		return null
	
	var target_pos: Vector2i = target as Vector2i
	
	# Проверяем валидность цели
	var valid_targets: Array[Vector2i] = get_valid_targets(entity, level)
	if not valid_targets.has(target_pos):
		return null
	
	# Проверяем AP
	if not entity.has_ap(ap_cost):
		return null
	
	# Находим путь
	var path: Array[Vector2i] = Pathfinder.find_path(entity.tile_position, target_pos, level)
	
	if path.is_empty():
		return null
	
	# Сохраняем путь
	last_path = path
	
	# Тратим AP
	entity.spend_ap(ap_cost)
	
	# Создаём действие перемещения
	return MoveAction.new(entity, path)
