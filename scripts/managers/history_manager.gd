class_name HistoryManager
extends RefCounted

# Сигнал об изменении состояния истории
signal history_changed()

# Структура записи: { entity: Entity, action: Action, round_number: int, turn_index: int }
var _history: Array[Dictionary] = []
var _level: Level = null
var _current_round: int = 0
var _current_turn_index: int = 0


func setup(level: Level) -> void:
	_level = level


# Начать новый раунд (вызывается RoundManager'ом)
func start_new_round(round_number: int) -> void:
	_current_round = round_number
	_current_turn_index = 0


# Записать действие в историю
func record_action(entity: Entity, action: Action) -> void:
	var record: Dictionary = {
		"entity": entity,
		"action": action,
		"round_number": _current_round,
		"turn_index": _current_turn_index
	}
	_history.append(record)
	emit_signal("history_changed")


# Увеличить индекс хода (вызывается при переходе к следующей сущности)
func advance_turn() -> void:
	_current_turn_index += 1


# === ЛОКАЛЬНЫЙ ОТКАТ ===
# Отменяет последнее действие указанной сущности
# Возвращает true если успешно
func undo_last_action(entity: Entity) -> bool:
	# Ищем последнее действие этой сущности
	var index: int = _find_last_action_index(entity)
	
	if index == -1:
		return false
	
	var record: Dictionary = _history[index]
	var action: Action = record["action"]
	
	# Выполняем откат
	action.undo(_level)
	
	# Удаляем из истории
	_history.remove_at(index)
	emit_signal("history_changed")
	
	return true


# Проверка возможности локального отката
func can_undo_last_action(entity: Entity) -> bool:
	return _find_last_action_index(entity) != -1


# === ПРОМЕЖУТОЧНЫЙ ОТКАТ ===
# Возвращает на начало текущего раунда
func undo_to_round_start() -> bool:
	if _current_round <= 1:
		return false
	
	# Получаем все действия текущего раунда
	var actions_to_undo: Array[Dictionary] = _get_actions_in_round(_current_round)
	
	if actions_to_undo.is_empty():
		return false
	
	# Откатываем в обратном порядке
	for i: int in range(actions_to_undo.size() - 1, -1, -1):
		var record: Dictionary = actions_to_undo[i]
		var action: Action = record["action"]
		action.undo(_level)
		_history.erase(record)
	
	emit_signal("history_changed")
	return true


# Проверка возможности промежуточного отката
func can_undo_to_round_start() -> bool:
	if _current_round <= 1:
		return false
	
	return _has_actions_in_round(_current_round)


# === ГЛОБАЛЬНЫЙ ОТКАТ ===
# Возвращает на один раунд назад
func undo_full_round() -> bool:
	if _current_round <= 1:
		return false
	
	# Сначала откатываем текущий раунд
	undo_to_round_start()
	
	# Теперь откатываем предыдущий раунд
	var previous_round: int = _current_round - 1
	var actions_to_undo: Array[Dictionary] = _get_actions_in_round(previous_round)
	
	if actions_to_undo.is_empty():
		return true  # Текущий раунд откатили, но предыдущий пуст
	
	# Откатываем в обратном порядке
	for i: int in range(actions_to_undo.size() - 1, -1, -1):
		var record: Dictionary = actions_to_undo[i]
		var action: Action = record["action"]
		action.undo(_level)
		_history.erase(record)
	
	# Уменьшаем номер текущего раунда
	_current_round -= 1
	emit_signal("history_changed")
	
	return true


# Проверка возможности глобального отката
func can_undo_full_round() -> bool:
	return _current_round > 1


# Получить количество действий в истории
func get_history_size() -> int:
	return _history.size()


# Получить текущий номер раунда
func get_current_round() -> int:
	return _current_round


# === ПРИВАТНЫЕ МЕТОДЫ ===

# Найти индекс последнего действия сущности
func _find_last_action_index(entity: Entity) -> int:
	for i: int in range(_history.size() - 1, -1, -1):
		if _history[i]["entity"] == entity:
			return i
	return -1


# Получить все действия в указанном раунде
func _get_actions_in_round(round_num: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for record: Dictionary in _history:
		if record["round_number"] == round_num:
			result.append(record)
	
	return result


# Проверить, есть ли действия в раунде
func _has_actions_in_round(round_num: int) -> bool:
	for record: Dictionary in _history:
		if record["round_number"] == round_num:
			return true
	return false
