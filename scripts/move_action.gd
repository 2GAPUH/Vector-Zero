class_name MoveAction
extends Action

# Скорость анимации перемещения (секунды на клетку)
const MOVE_SPEED: float = 0.25

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
		print("MoveAction: путь пуст")
		return false
	
	# Проверяем, что конечная позиция свободна
	if not level.is_cell_free(end_pos):
		var entity_at_end: Entity = level.get_entity_at(end_pos)
		if entity_at_end != entity:
			print("MoveAction: клетка занята")
			entity.move_fail()
			return false
	
	# Проверяем проходимость конечной клетки
	if not level.is_tile_passable(end_pos):
		print("MoveAction: клетка непроходима")
		entity.move_fail()
		return false
	
	print("MoveAction: перемещение от ", start_pos, " к ", end_pos)
	
	# Обновляем позицию на карте
	level.update_entity_position(start_pos, end_pos, entity)
	
	# Запускаем анимацию (без await - камера будет следить)
	_start_movement_animation()
	
	return true


# Запустить анимацию перемещения
func _start_movement_animation() -> void:
	# Обновляем tile_position сразу
	entity.tile_position = end_pos
	
	# Создаём tween для плавного движения к конечной точке
	var world_pos: Vector2 = entity.current_level.tile_to_local(end_pos)
	var total_time: float = MOVE_SPEED * path.size()
	
	var tween: Tween = entity.create_tween()
	tween.tween_property(entity, "global_position", world_pos, total_time).set_trans(Tween.TRANS_SINE)


# Отменить перемещение
func undo(level: Level) -> void:
	level.update_entity_position(end_pos, start_pos, entity)
	entity.tile_position = start_pos
	entity.global_position = level.tile_to_local(start_pos)
