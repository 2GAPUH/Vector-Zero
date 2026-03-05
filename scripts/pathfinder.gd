class_name Pathfinder
extends RefCounted

# Класс для узла в A*
class PathNode extends RefCounted:
	var position: Vector2i = Vector2i.ZERO
	var g_cost: int = 0  # Стоимость от старта
	var h_cost: int = 0  # Эвристика до цели
	var f_cost: int = 0  # g + h
	var parent: PathNode = null
	
	func _init(pos: Vector2i) -> void:
		position = pos
	
	func calculate_f_cost() -> void:
		f_cost = g_cost + h_cost


# 4 направления движения
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1)
]


# Найти путь от старта до цели
static func find_path(start: Vector2i, end: Vector2i, level: Level) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	
	# Если старт == цель
	if start == end:
		return result
	
	# Если цель непроходима
	if not level.is_tile_passable(end):
		return result
	
	# Инициализация
	var open_list: Array[PathNode] = []
	var closed_list: Dictionary = {}  # Vector2i -> bool
	
	var start_node: PathNode = PathNode.new(start)
	start_node.g_cost = 0
	start_node.h_cost = _calculate_distance(start, end)
	start_node.calculate_f_cost()
	
	open_list.append(start_node)
	
	while open_list.size() > 0:
		# Находим узел с минимальным f_cost
		var current: PathNode = _get_lowest_f_cost_node(open_list)
		
		# Если достигли цели
		if current.position == end:
			return _retrace_path(current)
		
		# Перемещаем из open в closed
		open_list.erase(current)
		closed_list[current.position] = true
		
		# Проверяем соседей
		for dir: Vector2i in DIRECTIONS:
			var neighbor_pos: Vector2i = current.position + dir
			
			# Пропускаем, если уже проверен
			if closed_list.has(neighbor_pos):
				continue
			
			# Проверяем проходимость
			if not level.is_tile_passable(neighbor_pos):
				closed_list[neighbor_pos] = true
				continue
			
			# Проверяем, не занята ли клетка (кроме цели)
			if neighbor_pos != end and not level.is_cell_free(neighbor_pos):
				closed_list[neighbor_pos] = true
				continue
			
			# Рассчитываем стоимость
			var tentative_g_cost: int = current.g_cost + 1
			
			# Ищем узел в open_list
			var neighbor_node: PathNode = _find_node_in_list(open_list, neighbor_pos)
			
			if neighbor_node == null:
				# Новый узел
				neighbor_node = PathNode.new(neighbor_pos)
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.h_cost = _calculate_distance(neighbor_pos, end)
				neighbor_node.calculate_f_cost()
				neighbor_node.parent = current
				open_list.append(neighbor_node)
			elif tentative_g_cost < neighbor_node.g_cost:
				# Нашли лучший путь
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.calculate_f_cost()
				neighbor_node.parent = current
	
	return result


# Получить все достижимые клетки в радиусе
static func get_reachable_tiles(start: Vector2i, level: Level, max_range: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var visited: Dictionary = {}
	
	# BFS для поиска достижимых клеток
	var queue: Array[Dictionary] = [{"pos": start, "dist": 0}]
	visited[start] = true
	
	while queue.size() > 0:
		var current: Dictionary = queue.pop_front()
		var current_pos: Vector2i = current["pos"]
		var current_dist: int = current["dist"]
		
		if current_dist <= max_range:
			result.append(current_pos)
		
		if current_dist >= max_range:
			continue
		
		for dir: Vector2i in DIRECTIONS:
			var neighbor_pos: Vector2i = current_pos + dir
			
			if visited.has(neighbor_pos):
				continue
			
			# Проверяем проходимость
			if not level.is_tile_passable(neighbor_pos):
				visited[neighbor_pos] = true
				continue
			
			# Проверяем, не занята ли клетка
			if not level.is_cell_free(neighbor_pos):
				visited[neighbor_pos] = true
				continue
			
			visited[neighbor_pos] = true
			queue.append({"pos": neighbor_pos, "dist": current_dist + 1})
	
	return result


# Проверить, достижима ли клетка
static func is_reachable(start: Vector2i, end: Vector2i, level: Level, max_range: int) -> bool:
	var path: Array[Vector2i] = find_path(start, end, level)
	return path.size() > 0 and path.size() <= max_range


# === ПРИВАТНЫЕ МЕТОДЫ ===

# Рассчитать эвристическое расстояние (манхэттенское)
static func _calculate_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


# Найти узел с минимальной стоимостью
static func _get_lowest_f_cost_node(list: Array[PathNode]) -> PathNode:
	var lowest: PathNode = list[0]
	for i: int in range(1, list.size()):
		if list[i].f_cost < lowest.f_cost:
			lowest = list[i]
		elif list[i].f_cost == lowest.f_cost and list[i].h_cost < lowest.h_cost:
			lowest = list[i]
	return lowest


# Найти узел в списке по позиции
static func _find_node_in_list(list: Array[PathNode], pos: Vector2i) -> PathNode:
	for node: PathNode in list:
		if node.position == pos:
			return node
	return null


# Восстановить путь от конца к началу
static func _retrace_path(end_node: PathNode) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var current: PathNode = end_node
	
	while current != null:
		result.append(current.position)
		current = current.parent
	
	# Разворачиваем путь (от старта к концу)
	result.reverse()
	
	# Убираем стартовую позицию (сущность уже там)
	if result.size() > 0:
		result.remove_at(0)
	
	return result
