class_name RoundManager
extends Node

# === СИГНАЛЫ ===
signal round_started(round_number: int)
signal turn_preparing(entity: Entity)
signal turn_started(entity: Entity)
signal turn_finished(entity: Entity)
signal round_finished(round_number: int)
signal entity_died(entity: Entity)

# === КОНСТАНТЫ ===
const TURN_DELAY: float = 0.5

# === ПЕРЕМЕННЫЕ ===
# Порядок ходов
var _turn_order: Array[Entity] = []
var _turn_index: int = 0
var _round_number: int = 0
var _is_active: bool = false

# Текущая сущность
var _current_entity: Entity = null

# Флаг ожидания подтверждения
var _waiting_for_turn_confirm: bool = false


# === ИНИЦИАЛИЗАЦИЯ ===

func initialize(entities: Array[Entity]) -> void:
		_turn_order.clear()
		
		for entity: Entity in entities:
				if entity.is_alive:
						_turn_order.append(entity)
		
		_shuffle_turn_order()
		
		_round_number = 0
		_turn_index = 0
		_is_active = false


func _shuffle_turn_order() -> void:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.randomize()
		
		for i: int in range(_turn_order.size() - 1, 0, -1):
				var j: int = rng.randi_range(0, i)
				var temp: Entity = _turn_order[i]
				_turn_order[i] = _turn_order[j]
				_turn_order[j] = temp


# === УПРАВЛЕНИЕ ИГРОЙ ===

func start_game() -> void:
		_is_active = true
		_start_round()


func _start_round() -> void:
		_round_number += 1
		_turn_index = 0
		
		# Подписываемся на смерть всех сущностей
		_connect_death_signals()
		
		emit_signal("round_started", _round_number)
		_prepare_current_turn()


# Подключить сигналы смерти
func _connect_death_signals() -> void:
		for entity: Entity in _turn_order:
				if not entity.is_connected("died", _on_entity_died):
						entity.connect("died", _on_entity_died)


# Обработка смерти сущности
func _on_entity_died(entity: Entity) -> void:
		print("RoundManager: Сущность умерла - ", entity.name)
		
		# Удаляем из очереди
		_remove_from_turn_order(entity)
		
		emit_signal("entity_died", entity)


# Удалить сущность из очереди
func _remove_from_turn_order(entity: Entity) -> void:
		var index: int = _turn_order.find(entity)
		if index != -1:
				_turn_order.remove_at(index)
				
				# Корректируем индекс текущего хода
				if index < _turn_index:
						_turn_index -= 1


# === УПРАВЛЕНИЕ ХОДАМИ ===

func _prepare_current_turn() -> void:
		if not _is_active:
				return
		
		# Пропускаем мёртвых сущностей
		while _turn_index < _turn_order.size() and not _turn_order[_turn_index].is_alive:
				_turn_index += 1
		
		if _turn_index >= _turn_order.size():
				_on_round_finished()
				return
		
		_current_entity = _turn_order[_turn_index]
		_waiting_for_turn_confirm = true
		
		emit_signal("turn_preparing", _current_entity)


func confirm_turn_start() -> void:
		if not _waiting_for_turn_confirm:
				return
		
		_waiting_for_turn_confirm = false
		
		if _current_entity == null or not _current_entity.is_alive:
				_turn_index += 1
				_prepare_current_turn()
				return
		
		# Подписываемся на завершение хода
		if not _current_entity.is_connected("turn_finished", _on_entity_turn_finished):
				_current_entity.connect("turn_finished", _on_entity_turn_finished)
		
		# Сначала сбрасываем очки, потом обновляем UI
		_current_entity._start_turn()
		emit_signal("turn_started", _current_entity)


func _on_entity_turn_finished() -> void:
		emit_signal("turn_finished", _current_entity)
		_turn_index += 1
		
		await get_tree().create_timer(TURN_DELAY).timeout
		_prepare_current_turn()


func _on_round_finished() -> void:
		emit_signal("round_finished", _round_number)
		call_deferred("_start_round")


# === ОТКАТЫ ===

func restart_current_round() -> void:
		_turn_index = 0
		_waiting_for_turn_confirm = false
		emit_signal("round_started", _round_number)
		_prepare_current_turn()


func start_previous_round() -> void:
		_round_number -= 1
		_turn_index = 0
		_waiting_for_turn_confirm = false
		emit_signal("round_started", _round_number)
		_prepare_current_turn()


# === УПРАВЛЕНИЕ СОСТОЯНИЕМ ===

func pause() -> void:
		_is_active = false


func resume() -> void:
		_is_active = true


# === ГЕТТЕРЫ ===

func get_current_entity() -> Entity:
		return _current_entity


func get_current_round() -> int:
		return _round_number


func is_hero_turn() -> bool:
		return _current_entity is Hero


func get_turn_order() -> Array[Entity]:
		return _turn_order.duplicate()


func is_active() -> bool:
		return _is_active
