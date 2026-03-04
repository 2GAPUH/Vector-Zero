class_name Pathfinder
extends RefCounted

# === A* АЛГОРИТМ ПОИСКА ПУТИ ===

# Найти путь от start до end
# Возвращает массив позиций (без стартовой)
func find_path(start: Vector2i, end: Vector2i, level: Level) -> Array[Vector2i]:
	# Проверка: начало и конец совпадают
	if start == end:
		return []
	
	# Проверка: конечная точка непроходима (стена)
	if not level.is_tile_passable(end):
		return []
	
	# Проверка: конечная точка занята
	if not level.is_cell_free(end):
		return []
	
	# A* алгоритм
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	
	# g_score: стоимость пути от старта до узла
	var g_score: Dictionary = {}
	g_score[start] = 0
	
	# f_score: g_score + эвристика
	var f_score: Dictionary = {}
	f_score[start] = _heuristic(start, end)
	
	while open_set.size() > 0:
		# Находим узел с минимальным f_score
		var current: Vector2i = _get_min_f_score(open_set, f_score)
		
		# Достигли цели
		if current == end:
			return _reconstruct_path(came_from, current)
		
		# Убираем из открытого множества
		open_set.erase(current)
		
		# Проверяем соседей
		for neighbor: Vector2i in _get_neighbors(current, level):
			var tentative_g: int = g_score[current] + 1
			
			# Нашли лучший путь к соседу
			if not g_score.has(neighbor) or tentative_g < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, end)
				
				if neighbor not in open_set:
					open_set.append(neighbor)
	
	# Путь не найден
	return []


# === ЭВРИСТИКА (Манхэттенское расстояние) ===
func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# === НАЙТИ УЗЕЛ С МИНИМАЛЬНЫМ F_SCORE ===
func _get_min_f_score(open_set: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var min_node: Vector2i = open_set[0]
	var min_value: int = f_score.get(min_node, 999999)
	
	for node: Vector2i in open_set:
		var value: int = f_score.get(node, 999999)
		if value < min_value:
			min_value = value
			min_node = node
	
	return min_node


# === ПОЛУЧИТЬ СОСЕДЕЙ (4 направления) ===
func _get_neighbors(pos: Vector2i, level: Level) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i.UP,    # (0, -1)
		Vector2i.DOWN,  # (0, 1)
		Vector2i.LEFT,  # (-1, 0)
		Vector2i.RIGHT  # (1, 0)
	]
	
	for dir: Vector2i in directions:
		var neighbor: Vector2i = pos + dir
		
		# Проверяем проходимость и свободу клетки
		if level.is_tile_passable(neighbor) and level.is_cell_free(neighbor):
			result.append(neighbor)
	
	return result


# === ВОССТАНОВИТЬ ПУТЬ ===
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	
	while came_from.has(current):
		current = came_from[current]
		path.insert(0, current)
	
	# Убираем стартовую позицию
	path.remove_at(0)
	return path


# === ПРОВЕРКА ПРОХОДИМОСТИ (для AI) ===
func is_passable(pos: Vector2i, level: Level) -> bool:
	return level.is_tile_passable(pos) and level.is_cell_free(pos)


# === НАЙТИ ПУТЬ С УЧЁТОМ ПРЕПЯТСТВИЙ (для AI) ===
# Возвращает путь и препятствие, если оно блокирует
func find_path_with_obstacle(start: Vector2i, end: Vector2i, level: Level) -> Dictionary:
	var result: Dictionary = {
		"path": [],
		"blocking_entity": null
	}
	
	# Проверяем прямую видимость
	var direct_path: Array[Vector2i] = _find_straight_path(start, end, level)
	
	if direct_path.size() > 0:
		result["path"] = direct_path
		return result
	
	# Прямого пути нет — ищем обход через A*
	var astar_path: Array[Vector2i] = find_path(start, end, level)
	
	if astar_path.size() > 0:
		result["path"] = astar_path
		return result
	
	# Путь заблокирован — находим препятствие
	result["blocking_entity"] = _find_blocking_entity(start, end, level)
	
	return result


# === ПРЯМОЙ ПУТЬ (для простой проверки) ===
func _find_straight_path(start: Vector2i, end: Vector2i, level: Level) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current: Vector2i = start
	
	while current != end:
		var direction: Vector2i = Vector2i(
			signi(end.x - current.x),
			signi(end.y - current.y)
		)
		
		# Ограничиваем до одного направления
		if absi(end.x - current.x) >= absi(end.y - current.y):
			direction.y = 0
		else:
			direction.x = 0
		
		var next: Vector2i = current + direction
		
		# Проверяем проходимость
		if not level.is_tile_passable(next):
			return []  # Стена
		
		if not level.is_cell_free(next):
			return []  # Занято
		
		path.append(next)
		current = next
	
	return path


# === НАЙТИ БЛОКИРУЮЩЕЕ ПРЕПЯТСТВИЕ ===
func _find_blocking_entity(start: Vector2i, end: Vector2i, level: Level) -> Entity:
	var current: Vector2i = start
	var visited: Array[Vector2i] = [start]
	
	# Идём по направлению к цели
	for _i: int in range(100):  # Защита от бесконечного цикла
		if current == end:
			break
		
		var direction: Vector2i = Vector2i(
			signi(end.x - current.x),
			signi(end.y - current.y)
		)
		
		# Ограничиваем до одного направления
		if absi(end.x - current.x) >= absi(end.y - current.y):
			direction.y = 0
		else:
			direction.x = 0
		
		var next: Vector2i = current + direction
		
		# Стена — не можем пройти
		if not level.is_tile_passable(next):
			return null
		
		# Занятая клетка
		if not level.is_cell_free(next):
			var entity: Entity = level.get_entity_at(next)
			if entity is Obstacle:
				return entity  # Нашли препятствие
			return null  # Другая сущность
		
		if next in visited:
			break
		
		visited.append(next)
		current = next
	
	return null
