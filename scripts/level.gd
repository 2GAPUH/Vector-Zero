extends Node2D
class_name Level

@onready var tile_map: TileMapLayer = $Walls

# Занятые клетки: {Vector2i: Entity}
var _occupied: Dictionary = {}

# Ссылка на менеджер истории
var history_manager: HistoryManager = null


func _ready() -> void:
		GameManager.set_level(self)


# Получить размер тайла
func get_tile_size() -> Vector2i:
		return tile_map.tile_set.tile_size


# Проверить, проходима ли клетка (нет стены)
func is_tile_passable(tile_pos: Vector2i) -> bool:
		return tile_map.get_cell_source_id(tile_pos) == -1


# Конвертировать координаты тайла в локальные
func tile_to_local(tile_pos: Vector2i) -> Vector2:
		return tile_map.map_to_local(tile_pos)


# Конвертировать локальные координаты в координаты тайла
func local_to_tile(world_pos: Vector2) -> Vector2i:
		return tile_map.local_to_map(world_pos)


# Зарегистрировать сущность на уровне
func register_entity(entity: Entity, tile_pos: Vector2i) -> void:
		if is_cell_free(tile_pos) and is_tile_passable(tile_pos):
				_occupied[tile_pos] = entity
				
				# Подписываемся на запросы действий
				if not entity.is_connected("request_action", _on_entity_request_action):
						entity.connect("request_action", _on_entity_request_action)
				
				print("Entity registered: ", entity.name)
				entity.setup(self)


# Обновить позицию сущности на карте
func update_entity_position(old_pos: Vector2i, new_pos: Vector2i, entity: Entity) -> void:
		_occupied.erase(old_pos)
		_occupied[new_pos] = entity


# Проверить, свободна ли клетка
func is_cell_free(tile_pos: Vector2i) -> bool:
		return not _occupied.has(tile_pos)


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


# Получить всех героев на уровне
func get_all_heroes() -> Array[Hero]:
		var heroes: Array[Hero] = []
		
		for pos: Vector2i in _occupied:
				if _occupied[pos] is Hero:
						heroes.append(_occupied[pos])
		
		return heroes


# Получить сущность по позиции
func get_entity_at(tile_pos: Vector2i) -> Entity:
		if _occupied.has(tile_pos):
				return _occupied[tile_pos]
		return null


# Обработчик запроса действия от сущности
func _on_entity_request_action(action: Action) -> void:
		var success: bool = action.execute(self)
		
		# Записываем в историю только успешные действия
		if success and history_manager != null:
				history_manager.record_action(action.entity, action)


# Установить менеджер истории
func set_history_manager(manager: HistoryManager) -> void:
		history_manager = manager
