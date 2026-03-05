class_name MoveAction
extends Action

# Путь для перемещения (все клетки пути)
var path: Array[Vector2i] = []

# Начальная позиция
var start_pos: Vector2i = Vector2i.ZERO

# Конечная позиция
var end_pos: Vector2i = Vector2i.ZERO


# Конструктор с путём
func _init(actor: Entity, move_path: Array[Vector2i]) -> void:
	super(actor)
	path = move_path
	if path.size() > 0:
		start_pos = actor.tile_position
		end_pos = path[path.size() - 1]


# Выполнить перемещение по пути
func execute(level: Level) -> bool:
	if path.is_empty():
		return false
	
	# Проверяем, что стартовая позиция свободна
	if not level.is_cell_free(end_pos):
		# Возможно, клетка занята тем, кто там стоит сейчас
		# Проверяем только если это не сама сущность
		var entity_at_end: Entity = level.get_entity_at(end_pos)
		if entity_at_end != entity:
			entity.move_fail()
			return false
	
	# Проверяем проходимость конечной клетки
	if not level.is_tile_passable(end_pos):
		entity.move_fail()
		return false
	
	# Обновляем позицию на карте
	level.update_entity_position(start_pos, end_pos, entity)
	
	# Анимация перемещения по пути
	_animate_movement()
	
	return true


# Анимация перемещения по клеткам пути
func _animate_movement() -> void:
	# Последовательная анимация по каждой клетке
	for i: int in range(path.size()):
		var target_pos: Vector2i = path[i]
		var world_pos: Vector2 = entity.current_level.tile_to_local(target_pos)
		
		# Создаём tween для движения к следующей клетке
		var tween: Tween = entity.create_tween()
		tween.tween_property(entity, "global_position", world_pos, 0.15).set_trans(Tween.TRANS_SINE)
		
		# Обновляем tile_position сразу
		entity.tile_position = target_pos
		
		# Ждём завершения анимации
		await tween.finished


# Отменить перемещение
func undo(level: Level) -> void:
	# Возвращаем сущность на стартовую позицию
	level.update_entity_position(end_pos, start_pos, entity)
	entity.tile_position = start_pos
	entity.global_position = level.tile_to_local(start_pos)
