class_name RoundManager
extends Node

# === МЕНЕДЖЕР РАУНДОВ ===

# Сигналы для оповещения о событиях
signal round_started(round_number: int)
signal turn_preparing(entity: Entity)
signal turn_started(entity: Entity)
signal turn_finished(entity: Entity)
signal round_finished(round_number: int)

# Задержка между ходами (в секундах)
const TURN_DELAY: float = 0.5

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
	
	# Копируем только живые сущности
	for entity: Entity in entities:
		if entity.is_alive:
			_turn_order.append(entity)
	
	_shuffle_turn_order()
	
	_round_number = 0
	_turn_index = 0
	_is_active = false


# === ПЕРЕМЕШАТЬ ПОРЯДОК ===
func _shuffle_turn_order() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	for i: int in range(_turn_order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Entity = _turn_order[i]
		_turn_order[i] = _turn_order[j]
		_turn_order[j] = temp


# === НАЧАТЬ ИГРУ ===
func start_game() -> void:
	_is_active = true
	_start_round()


# === НАЧАТЬ РАУНД ===
func _start_round() -> void:
	_round_number += 1
	_turn_index = 0
	
	# Обновляем порядок ходов (убираем мёртвых)
	_remove_dead_entities()
	
	emit_signal("round_started", _round_number)
	
	_prepare_current_turn()


# === УДАЛИТЬ МЁРТВЫХ СУЩНОСТЕЙ ИЗ ОЧЕРЕДИ ===
func _remove_dead_entities() -> void:
	var new_order: Array[Entity] = []
	for entity: Entity in _turn_order:
		if entity.is_alive:
			new_order.append(entity)
	_turn_order = new_order


# === ПОДГОТОВКА ХОДА ===
func _prepare_current_turn() -> void:
	if not _is_active:
		return
	
	# Проверяем: раунд закончился?
	if _turn_index >= _turn_order.size():
		_on_round_finished()
		return
	
	_current_entity = _turn_order[_turn_index]
	
	# Пропускаем неживых
	if not _current_entity.is_alive:
		_turn_index += 1
		_prepare_current_turn()
		return
	
	_waiting_for_turn_confirm = true
	
	emit_signal("turn_preparing", _current_entity)


# === ПОДТВЕРДИТЬ НАЧАЛО ХОДА ===
func confirm_turn_start() -> void:
	if not _waiting_for_turn_confirm:
		return
	
	_waiting_for_turn_confirm = false
	
	# Подписываемся на завершение хода
	if not _current_entity.is_connected("turn_finished", _on_entity_turn_finished):
		_current_entity.connect("turn_finished", _on_entity_turn_finished)
	
	emit_signal("turn_started", _current_entity)
	
	# Запускаем ход сущности
	_current_entity._start_turn()


# === ЗАВЕРШЕНИЕ ХОДА СУЩНОСТИ ===
func _on_entity_turn_finished() -> void:
	emit_signal("turn_finished", _current_entity)
	_turn_index += 1
	
	# Задержка перед следующим ходом
	await get_tree().create_timer(TURN_DELAY).timeout
	_prepare_current_turn()


# === ЗАВЕРШЕНИЕ РАУНДА ===
func _on_round_finished() -> void:
	emit_signal("round_finished", _round_number)
	call_deferred("_start_round")


# === ПЕРЕЗАПУСК ТЕКУЩЕГО РАУНДА ===
func restart_current_round() -> void:
	_turn_index = 0
	_waiting_for_turn_confirm = false
	emit_signal("round_started", _round_number)
	_prepare_current_turn()


# === НАЧАТЬ ПРЕДЫДУЩИЙ РАУНД ===
func start_previous_round() -> void:
	_round_number -= 1
	if _round_number < 1:
		_round_number = 1
	_turn_index = 0
	_waiting_for_turn_confirm = false
	emit_signal("round_started", _round_number)
	_prepare_current_turn()


# === ПАУЗА ===
func pause() -> void:
	_is_active = false


# === ПРОДОЛЖИТЬ ===
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
