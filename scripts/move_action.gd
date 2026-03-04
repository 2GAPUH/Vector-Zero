class_name MoveAction
extends Action

# === ДЕЙСТВИЕ: ПЕРЕМЕЩЕНИЕ ===

# Путь перемещения (массив позиций)
var path: Array[Vector2i] = []

# Начальная позиция
var start_pos: Vector2i = Vector2i.ZERO

# Конечная позиция
var target_pos: Vector2i = Vector2i.ZERO


# Инициализация с путём
func _init(actor: Entity, move_path: Array[Vector2i]) -> void:
	super(actor)
	path = move_path
	start_pos = actor.tile_position
	if move_path.size() > 0:
		target_pos = move_path[move_path.size() - 1]


# === ВЫПОЛНЕНИЕ ПЕРЕМЕЩЕНИЯ ===
func execute(level: Level) -> bool:
	if path.is_empty():
		entity.move_fail()
		return false
	
	# Обновляем позицию на уровне
	level.update_entity_position(start_pos, target_pos, entity)
	
	# Обновляем позицию сущности
	entity.tile_position = target_pos
	
	# Запускаем последовательное перемещение
	entity.follow_path(path)
	
	return true


# === ОТКАТ ПЕРЕМЕЩЕНИЯ ===
func undo(level: Level) -> void:
	# Возвращаем сущность на старую позицию
	level.update_entity_position(target_pos, start_pos, entity)
	entity.tile_position = start_pos
	
	# Мгновенно перемещаем
	entity.global_position = level.tile_to_local(start_pos)
