extends Node2D
class_name Level

# === УРОВЕНЬ (КАРТА) ===

@onready var tile_map: TileMapLayer = $Walls

# Занятые клетки: {Vector2i: Entity}
var _occupied: Dictionary = {}

# Ссылка на менеджер истории
var history_manager: HistoryManager = null

# Слой подсветки
var _highlight_layer: Node2D = null

# Префаб для подсветки клетки
var _highlight_scene: PackedScene = null


func _ready() -> void:
	GameManager.set_level(self)
	_create_highlight_layer()


# === СОЗДАТЬ СЛОЙ ПОДСВЕТКИ ===
func _create_highlight_layer() -> void:
	_highlight_layer = Node2D.new()
	_highlight_layer.name = "HighlightLayer"
	_highlight_layer.z_index = 10  # Поверх тайлов
	add_child(_highlight_layer)


# === ПОЛУЧИТЬ РАЗМЕР ТАЙЛА ===
func get_tile_size() -> Vector2i:
	return tile_map.tile_set.tile_size


# === ПРОВЕРИТЬ ПРОХОДИМОСТЬ КЛЕТКИ (нет стены) ===
func is_tile_passable(tile_pos: Vector2i) -> bool:
	return tile_map.get_cell_source_id(tile_pos) == -1


# === КОНВЕРТАЦИЯ КООРДИНАТ ===
func tile_to_local(tile_pos: Vector2i) -> Vector2:
	return tile_map.map_to_local(tile_pos)


func local_to_tile(world_pos: Vector2) -> Vector2i:
	return tile_map.local_to_map(world_pos)


# === РЕГИСТРАЦИЯ СУЩНОСТИ ===
func register_entity(entity: Entity, tile_pos: Vector2i) -> void:
	if is_cell_free(tile_pos) and is_tile_passable(tile_pos):
		_occupied[tile_pos] = entity
		
		# Подписываемся на запросы действий
		if not entity.is_connected("request_action", _on_entity_request_action):
			entity.connect("request_action", _on_entity_request_action)
		
		print("Entity registered: ", entity.name)
		entity.setup(self)


# === РЕГИСТРАЦИЯ ПРЕПЯТСТВИЯ (без подписки на действия) ===
func register_obstacle(obstacle: Obstacle, tile_pos: Vector2i) -> void:
	if is_cell_free(tile_pos) and is_tile_passable(tile_pos):
		_occupied[tile_pos] = obstacle
		obstacle.setup(self)
		obstacle.tile_position = tile_pos
		print("Obstacle registered at: ", tile_pos)


# === ОБНОВЛЕНИЕ ПОЗИЦИИ СУЩНОСТИ ===
func update_entity_position(old_pos: Vector2i, new_pos: Vector2i, entity: Entity) -> void:
	_occupied.erase(old_pos)
	_occupied[new_pos] = entity


# === УДАЛЕНИЕ СУЩНОСТИ С КАРТЫ ===
func remove_entity(entity: Entity) -> void:
	_occupied.erase(entity.tile_position)


# === ПРОВЕРКА СВОБОДНОСТИ КЛЕТКИ ===
func is_cell_free(tile_pos: Vector2i) -> bool:
	return not _occupied.has(tile_pos)


# === ПОЛУЧИТЬ СУЩНОСТЬ ПО ПОЗИЦИИ ===
func get_entity_at(tile_pos: Vector2i) -> Entity:
	if _occupied.has(tile_pos):
		return _occupied[tile_pos]
	return null


# === ПОЛУЧИТЬ ПОЗИЦИЮ БЛИЖАЙШЕГО ГЕРОЯ ===
func get_nearest_hero_position(from_pos: Vector2i) -> Vector2i:
	var nearest_pos: Vector2i = Vector2i.ZERO
	var nearest_dist: int = -1
	
	for pos: Vector2i in _occupied:
		var entity: Entity = _occupied[pos]
		if entity is Hero and entity.is_alive:
			var dist: int = absi(pos.x - from_pos.x) + absi(pos.y - from_pos.y)
			if nearest_dist == -1 or dist < nearest_dist:
				nearest_dist = dist
				nearest_pos = pos
	
	return nearest_pos


# === ПОЛУЧИТЬ ВСЕХ ГЕРОЕВ ===
func get_all_heroes() -> Array[Hero]:
	var heroes: Array[Hero] = []
	
	for pos: Vector2i in _occupied:
		if _occupied[pos] is Hero and _occupied[pos].is_alive:
			heroes.append(_occupied[pos])
	
	return heroes


# === ПОЛУЧИТЬ ВСЕХ ВРАГОВ ===
func get_all_enemies() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	
	for pos: Vector2i in _occupied:
		if _occupied[pos] is Enemy and _occupied[pos].is_alive:
			enemies.append(_occupied[pos])
	
	return enemies


# === ПОЛУЧИТЬ ВСЕ ЖИВЫЕ СУЩНОСТИ ===
func get_all_living_entities() -> Array[Entity]:
	var entities: Array[Entity] = []
	
	for pos: Vector2i in _occupied:
		var entity: Entity = _occupied[pos]
		if entity.is_alive and not entity is Obstacle:
			entities.append(entity)
	
	return entities


# === СОЗДАТЬ ТРУП ===
func spawn_corpse(from_entity: Entity) -> void:
	var corpse: Obstacle = Obstacle.create_corpse(from_entity)
	
	# Создаём визуал для трупа
	var sprite: Sprite2D = Sprite2D.new()
	sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Серый цвет
	sprite.scale = Vector2(0.8, 0.8)
	corpse.add_child(sprite)
	
	# Регистрируем на уровне
	register_obstacle(corpse, from_entity.tile_position)
	corpse.setup_corpse(self, from_entity.tile_position)
	add_child(corpse)
	
	print("Corpse spawned at: ", from_entity.tile_position)


# === ОБРАБОТЧИК ЗАПРОСА ДЕЙСТВИЯ ===
func _on_entity_request_action(action: Action) -> void:
	var success: bool = action.execute(self)
	
	# Записываем в историю только успешные действия
	if success and history_manager != null:
		history_manager.record_action(action.entity, action)


# === УСТАНОВИТЬ МЕНЕДЖЕР ИСТОРИИ ===
func set_history_manager(manager: HistoryManager) -> void:
	history_manager = manager


# === ПОДСВЕТКА КЛЕТОК ===

# Очистить подсветку
func clear_highlight() -> void:
	for child: Node in _highlight_layer.get_children():
		child.queue_free()


# Подсветить клетки
func highlight_tiles(tiles: Array[Vector2i], color: Color) -> void:
	clear_highlight()
	
	for tile_pos: Vector2i in tiles:
		var highlight: ColorRect = _create_highlight_tile(tile_pos, color)
		_highlight_layer.add_child(highlight)


# Создать элемент подсветки
func _create_highlight_tile(tile_pos: Vector2i, color: Color) -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	var tile_size: Vector2i = get_tile_size()
	
	rect.color = color
	rect.size = Vector2(tile_size.x, tile_size.y)
	rect.position = tile_to_local(tile_pos) - Vector2(tile_size.x / 2.0, tile_size.y / 2.0)
	rect.z_index = 10
	
	return rect


# === ПРОВЕРКА: ЯВЛЯЕТСЯ ЛИ КЛЕТКА ЦЕЛЬЮ ДЛЯ АТАКИ ===
func is_valid_attack_target(tile_pos: Vector2i, attacker: Entity) -> bool:
	var entity: Entity = get_entity_at(tile_pos)
	if entity == null:
		return false
	if entity == attacker:
		return false
	if entity.is_alive or entity is Obstacle:
		return true
	return false
