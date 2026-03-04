class_name MoveAbility
extends Ability

# === СПОСОБНОСТЬ: БАЗОВОЕ ПЕРЕМЕЩЕНИЕ ===
# Не тратит AP
# Дальность = текущий запас перемещения (move_pool)


func _init() -> void:
	name = "Перемещение"
	description = "Базовое перемещение. Не тратит AP."
	cost = 0


# === МОЖНО ЛИ ИСПОЛЬЗОВАТЬ ===
func can_use() -> bool:
	if not super.can_use():
		return false
	
	# Нужен хотя бы 1 запас перемещения
	if entity.move_pool <= 0:
		return false
	
	# Должна быть хотя бы одна достижимая клетка
	return get_valid_targets().size() > 0


# === ПОЛУЧИТЬ ВАЛИДНЫЕ ЦЕЛИ ===
func get_valid_targets() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	
	if entity == null or entity.current_level == null:
		return result
	
	var pathfinder: Pathfinder = Pathfinder.new()
	var range: int = entity.move_pool
	
	# Перебираем все клетки в радиусе
	for x: int in range(-range, range + 1):
		for y: int in range(-range, range + 1):
			if x == 0 and y == 0:
				continue
			
			var target: Vector2i = entity.tile_position + Vector2i(x, y)
			
			# Проверяем манхэттенское расстояние
			if absi(x) + absi(y) > range:
				continue
			
			# Ищем путь
			var path: Array[Vector2i] = pathfinder.find_path(
				entity.tile_position,
				target,
				entity.current_level
			)
			
			# Путь существует и его длина <= range
			if path.size() > 0 and path.size() <= range:
				result.append(target)
	
	return result


# === ВЫПОЛНИТЬ ПЕРЕМЕЩЕНИЕ ===
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
	
	# Тратим запас перемещения
	entity.spend_move_pool(path.size())
	
	# Создаём действие перемещения
	var action: MoveAction = MoveAction.new(entity, path)
	entity.emit_signal("request_action", action)
	
	return true


# === ДАЛЬНОСТЬ ===
func get_range() -> int:
	if entity != null:
		return entity.move_pool
	return 0


# === ЦВЕТ ПОДСВЕТКИ ===
func get_highlight_color() -> Color:
	return Color(0.2, 0.8, 0.2, 0.5)  # Зелёный
