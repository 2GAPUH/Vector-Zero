class_name DashAbility
extends Ability

# === СПОСОБНОСТЬ: РЫВОК ===
# Стоимость: 1 AP
# Утраивает базовый запас перемещения


# Множитель рывка
const DASH_MULTIPLIER: int = 3


func _init() -> void:
	name = "Рывок"
	description = "Утраивает запас перемещения. Стоимость: 1 AP"
	cost = 1


# === МОЖНО ЛИ ИСПОЛЬЗОВАТЬ ===
func can_use() -> bool:
	if not super.can_use():
		return false
	
	# Должна быть хотя бы одна достижимая клетка
	return get_valid_targets().size() > 0


# === ПОЛУЧИТЬ ВАЛИДНЫЕ ЦЕЛИ ===
func get_valid_targets() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	
	if entity == null or entity.current_level == null:
		return result
	
	var pathfinder: Pathfinder = Pathfinder.new()
	
	# Утраиваем БАЗОВЫЙ запас перемещения
	var dash_range: int = entity.base_move_pool * DASH_MULTIPLIER
	
	# Перебираем все клетки в радиусе
	for x: int in range(-dash_range, dash_range + 1):
		for y: int in range(-dash_range, dash_range + 1):
			if x == 0 and y == 0:
				continue
			
			var target: Vector2i = entity.tile_position + Vector2i(x, y)
			
			# Проверяем манхэттенское расстояние
			if absi(x) + absi(y) > dash_range:
				continue
			
			# Ищем путь
			var path: Array[Vector2i] = pathfinder.find_path(
				entity.tile_position,
				target,
				entity.current_level
			)
			
			# Путь существует и его длина <= dash_range
			if path.size() > 0 and path.size() <= dash_range:
				result.append(target)
	
	return result


# === ВЫПОЛНИТЬ РЫВОК ===
func execute(target: Variant) -> bool:
	if not target is Vector2i:
		return false
	
	if not is_valid_target(target):
		return false
	
	var pathfinder: Pathfinder = Pathfinder.new()
	var path: Array[Vector2i] = pathfinder.find_path(
		entity.tile_position,
		target,
		entity.current_level
	)
	
	if path.is_empty():
		return false
	
	# Тратим AP
	entity.spend_ap(cost)
	
	# Рассчитываем новый запас перемещения
	var dash_pool: int = entity.base_move_pool * DASH_MULTIPLIER
	entity.move_pool = dash_pool - path.size()
	entity.emit_signal("move_pool_changed", entity.move_pool)
	
	# Создаём действие перемещения
	var action: MoveAction = MoveAction.new(entity, path)
	entity.emit_signal("request_action", action)
	
	return true


# === ДАЛЬНОСТЬ ===
func get_range() -> int:
	if entity != null:
		return entity.base_move_pool * DASH_MULTIPLIER
	return 6


# === ЦВЕТ ПОДСВЕТКИ ===
func get_highlight_color() -> Color:
	return Color(1.0, 0.8, 0.2, 0.5)  # Жёлтый/Оранжевый
