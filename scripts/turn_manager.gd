extends Node
class_name TurnQueue

signal turn_started(entity)

# структура элемента очереди: { "entity": Node, "time": int }
var _queue: Array = []
var _current_entry: Dictionary = {}
var _is_active: bool = false

# стандартная стоимость действия, от которой вычитаем скорость
const BASE_ACTION_COST: int = 20

func _ready() -> void:
	pass

# инициализация очередь
func initialize(entities: Array) -> void:
	_queue.clear()
	for entity: Entity in entities:
		_add_to_queue(entity, BASE_ACTION_COST - entity.speed) 
	
	_sort_queue()

func start_queue() -> void:
	_is_active = true
	_play_next_turn()

func stop_queue() -> void:
	_is_active = false

func _play_next_turn() -> void:
	print_queue()
	
	if not _is_active or _queue.is_empty():
		return
	
	# сущность с наименьшим временем
	_current_entry = _queue.pop_front()
	var current_entity: Entity = _current_entry.entity
	
	emit_signal("turn_started", current_entity)
	
	# подписываемся на завершение хода (один вызов)
	if not current_entity.is_connected("turn_finished", Callable(self, "_on_turn_finished")):
		current_entity.connect("turn_finished", Callable(self, "_on_turn_finished"), CONNECT_ONE_SHOT)
	
	# действие
	current_entity._start_turn()

func _on_turn_finished() -> void:
	if not _is_active: return
	
	# следующий ход
	var entity: Entity = _current_entry.entity
	var current_time: int = _current_entry.time
	
	
	# текущее + 20 - скорость
	# чтобы не стала отрицательной при высокой скорости
	var cost = max(1, BASE_ACTION_COST - entity.speed) 
	var next_time = current_time + cost
	
	# возвращаем в очередь с новым временем
	_add_to_queue(entity, next_time)
	_sort_queue()
	
	# следующий ход
	call_deferred("_play_next_turn")

# метод добавления
func _add_to_queue(entity: Node, time: int) -> void:
	_queue.append({
		"entity": entity,
		"time": time
	})

# сортировка от меньшего к большему
func _sort_queue() -> void:
	_queue.sort_custom(func(a, b): return a.time < b.time)

func print_queue() -> void:
	var s = "Queue: "
	for item in _queue:
		s += item.entity.name + "(" + str(item.time) + ") -> "
	print(s)
