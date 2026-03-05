class_name MoveAbility
extends Ability

# Ссылка на путь (для внешнего использования)
var last_path: Array[Vector2i] = []


func _init() -> void:
	ability_name = "Перемещение"
	description = "Переместиться в указанную точку"
	ap_cost = 0
	range = 2
	target_type = TargetType.TILE


# Получить валидные цели (клетки, куда можно переместиться)
func get_valid_targets(entity: Entity, level: Level) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var start_pos: Vector2i = entity.tile_position
	
	# Получаем все достижимые клетки через A*
	result = Pathfinder.get_reachable_tiles(start_pos, level, range)
	
	# Убираем текущую позицию
	result.erase(start_pos)
	
	return result


# Создать действие перемещения
func create_action(entity: Entity, target: Variant, level: Level) -> Action:
	if not target is Vector2i:
		return null
	
	var target_pos: Vector2i = target as Vector2i
	
	# Проверяем валидность цели
	var valid_targets: Array[Vector2i] = get_valid_targets(entity, level)
	if not valid_targets.has(target_pos):
		return null
	
	# Находим путь
	var path: Array[Vector2i] = Pathfinder.find_path(entity.tile_position, target_pos, level)
	
	if path.is_empty():
		return null
	
	# Сохраняем путь
	last_path = path
	
	# Создаём действие перемещения
	return MoveAction.new(entity, path)
