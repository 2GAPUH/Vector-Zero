extends Node2D
class_name Level

@onready var tile_map: TileMapLayer = $Walls

# Занятые клетки: {Vector2i: Entity}
var _occupied: Dictionary = {}

# Ссылка на менеджер истории
var history_manager: HistoryManager = null

# Сигнал о завершении действия (для обновления UI)
signal action_completed


func _ready() -> void:
	GameManager.set_level(self)


# === КОНВЕРТАЦИЯ КООРДИНАТ ===

# Получить размер тайла
func get_tile_size() -> Vector2i:
	return tile_map.tile_set.tile_size


# Конвертировать координаты тайла в локальные
func tile_to_local(tile_pos: Vector2i) -> Vector2:
	return tile_map.map_to_local(tile_pos)


# Конвертировать локальные координаты в координаты тайла
func local_to_tile(world_pos: Vector2) -> Vector2i:
	return tile_map.local_to_map(world_pos)


# === ПРОХОДИМОСТЬ ===

# Проверить, проходима ли клетка (нет стены)
func is_tile_passable(tile_pos: Vector2i) -> bool:
	return tile_map.get_cell_source_id(tile_pos) == -1


# Проверить, свободна ли клетка
func is_cell_free(tile_pos: Vector2i) -> bool:
	return not _occupied.has(tile_pos)


# === РЕГИСТРАЦИЯ СУЩНОСТЕЙ ===

# Зарегистрировать сущность на уровне
func register_entity(entity: Entity, tile_pos: Vector2i) -> void:
	register_entity_at_position(entity, tile_pos)


# Зарегистрировать сущность на конкретной позиции
func register_entity_at_position(entity: Entity, tile_pos: Vector2i) -> void:
	if is_cell_free(tile_pos) and is_tile_passable(tile_pos):
		_occupied[tile_pos] = entity
		
		# Подписываемся на запросы действий
		if not entity.is_connected("request_action", _on_entity_request_action):
			entity.connect("request_action", _on_entity_request_action)
		
		# Подписываемся на смерть
		if not entity.is_connected("died", _on_entity_died):
			entity.connect("died", _on_entity_died)
		
		print("Entity registered: ", entity.name, " at ", tile_pos)
		entity.setup(self)


# Удалить сущность с уровня
func unregister_entity(entity: Entity) -> void:
	# Находим позицию сущности
	for pos: Vector2i in _occupied:
		if _occupied[pos] == entity:
			_occupied.erase(pos)
			print("Entity unregistered: ", entity.name)
			break


# Обновить позицию сущности на карте
func update_entity_position(old_pos: Vector2i, new_pos: Vector2i, entity: Entity) -> void:
	_occupied.erase(old_pos)
	_occupied[new_pos] = entity


# === ПОЛУЧЕНИЕ СУЩНОСТЕЙ ===

# Получить сущность по позиции
func get_entity_at(tile_pos: Vector2i) -> Entity:
	if _occupied.has(tile_pos):
		return _occupied[tile_pos]
	return null


# Получить всех героев на уровне
func get_all_heroes() -> Array[Hero]:
	var heroes: Array[Hero] = []
	
	for pos: Vector2i in _occupied:
		if _occupied[pos] is Hero:
			heroes.append(_occupied[pos])
	
	return heroes


# Получить всех врагов на уровне
func get_all_enemies() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	
	for pos: Vector2i in _occupied:
		if _occupied[pos] is Enemy:
			enemies.append(_occupied[pos])
	
	return enemies


# Получить позицию ближайшего героя (для AI врагов)
func get_nearest_hero_position(from_pos: Vector2i) -> Vector2i:
	var nearest_pos: Vector2i = Vector2i.ZERO
	var nearest_dist: int = -1
	
	for pos: Vector2i in _occupied:
		if _occupied[pos] is Hero:
			var dist: int = abs(pos.x - from_pos.x) + abs(pos.y - from_pos.y)
			if nearest_dist == -1 or dist < nearest_dist:
				nearest_dist = dist
				nearest_pos = pos
	
	return nearest_pos


# Получить ближайшего героя
func get_nearest_hero(from_pos: Vector2i) -> Hero:
	var nearest: Hero = null
	var nearest_dist: int = -1
	
	for pos: Vector2i in _occupied:
		var entity: Entity = _occupied[pos]
		if entity is Hero and entity.is_alive:
			var dist: int = abs(pos.x - from_pos.x) + abs(pos.y - from_pos.y)
			if nearest_dist == -1 or dist < nearest_dist:
				nearest_dist = dist
				nearest = entity
	
	return nearest


# === ОБРАБОТЧИКИ СОБЫТИЙ ===

# Обработчик запроса действия от сущности
func _on_entity_request_action(action: Action) -> void:
	var success: bool = action.execute(self)
	
	# Записываем в историю только успешные действия
	if success and history_manager != null:
		history_manager.record_action(action.entity, action)
	
	# Отправляем сигнал о завершении действия
	emit_signal("action_completed")


# Обработчик смерти сущности
func _on_entity_died(entity: Entity) -> void:
	print("Entity died: ", entity.name)
	# Уведомляем RoundManager через сигнал (если подключён)


# === МЕНЕДЖЕР ИСТОРИИ ===

# Установить менеджер истории
func set_history_manager(manager: HistoryManager) -> void:
	history_manager = manager


# === ОТЛАДКА ===

# Получить все занятые клетки (для отладки)
func get_occupied_cells() -> Dictionary:
	return _occupied.duplicate()
