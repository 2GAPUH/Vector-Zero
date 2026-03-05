extends Area2D
class_name Entity

# Сигнал о завершении хода
signal turn_finished

# Сигнал о запросе выполнения действия
signal request_action(action: Action)

# Позиция на сетке
var tile_position: Vector2i = Vector2i.ZERO

# Вектор движения (для совместимости)
var movement_vect: Vector2i = Vector2i.ZERO

# Скорость (может использоваться в будущем)
@export var speed: int = 1

# Ссылка на уровень
var current_level: Level = null

# Контроллер для AI (null для игрока)
var controller: Controller = null


# Начать ход (переопределяется в наследниках)
func _start_turn() -> void:
	# Базовая реализация - сразу завершаем ход
	emit_signal("turn_finished")


# Инициализация сущности на уровне
func setup(level: Level) -> void:
	current_level = level
	tile_position = level.local_to_tile(position)


# Успешное перемещение
func move_success(direction: Vector2i) -> void:
	print("Move success")
	tile_position += direction
	
	# Плавная анимация перемещения
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", current_level.tile_to_local(tile_position), 0.3).set_trans(Tween.TRANS_SINE)


# Неудачное перемещение
func move_fail() -> void:
	print("Move failed")


# Завершить ход
func end_turn() -> void:
	emit_signal("turn_finished")
