class_name MoveAction
extends Action

# Скорость анимации перемещения (секунды на клетку)
const MOVE_SPEED: float = 0.15

# Путь для перемещения (все клетки пути)
var path: Array[Vector2i] = []

# Начальная позиция
var start_pos: Vector2i = Vector2i.ZERO

# Конечная позиция
var end_pos: Vector2i = Vector2i.ZERO

# Длина пути (для вычитания из move_budget)
var path_length: int = 0

# Сигнал о завершении анимации
signal animation_finished


# Конструктор с путём
func _init(actor: Entity, move_path: Array[Vector2i]) -> void:
		super(actor)
		path = move_path
		if path.size() > 0:
				start_pos = actor.tile_position
				end_pos = path[path.size() - 1]
				path_length = path.size()


# Выполнить перемещение по пути
func execute(level: Level) -> bool:
		if path.is_empty():
				print("MoveAction: путь пуст")
				return false
		
		# Получаем актуальную начальную позицию из _occupied
		# tile_position может быть ещё не обновлён после предыдущего движения
		var actual_start: Vector2i = level.get_entity_position(entity)
		
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
		
		# Списываем запас движения
		if not entity.use_move_budget(path_length):
				print("MoveAction: недостаточно запаса движения")
				return false
		
		print("MoveAction: перемещение от ", actual_start, " к ", end_pos, " (длина: ", path_length, ")")
		
		# Обновляем позицию на карте (используем actual_start)
		level.update_entity_position(actual_start, end_pos, entity)
		
		# Запускаем пошаговую анимацию
		_start_step_by_step_animation()
		
		return true


# Запустить пошаговую анимацию перемещения
func _start_step_by_step_animation() -> void:
		# Создаём последовательный tween для каждой клетки пути
		var tween: Tween = entity.create_tween()
		
		for i: int in range(path.size()):
				var cell: Vector2i = path[i]
				var world_pos: Vector2 = entity.current_level.tile_to_local(cell)
				
				# Добавляем шаг анимации для каждой клетки
				tween.tween_property(entity, "global_position", world_pos, MOVE_SPEED).set_trans(Tween.TRANS_SINE)
		
		# После завершения анимации обновляем tile_position и отправляем сигнал
		tween.tween_callback(_on_animation_finished)
		
		# ОБНОВЛЯЕМ tile_position ТОЛЬКО ПОСЛЕ анимации (в колбэке)
		# Но позиция в _occupied уже обновлена в execute(), чтобы занять клетку


# Called when animation finishes
func _on_animation_finished() -> void:
		# Обновляем tile_position только после завершения анимации
		entity.tile_position = end_pos
		emit_signal("animation_finished")


# Отменить перемещение
func undo(level: Level) -> void:
		level.update_entity_position(end_pos, start_pos, entity)
		entity.tile_position = start_pos
		entity.global_position = level.tile_to_local(start_pos)
		
		# Возвращаем запас движения
		entity.move_budget += path_length
