class_name RoundManager
extends Node

# Сигналы для оповещения о событиях
signal round_started(round_number: int)
signal turn_started(entity: Entity)
signal turn_finished(entity: Entity)
signal round_finished(round_number: int)

# Задержка между ходами (в секундах)
const TURN_DELAY: float = 0.5

# Фиксированный порядок ходов (устанавливается один раз)
var _turn_order: Array[Entity] = []
var _turn_index: int = 0
var _round_number: int = 0
var _is_active: bool = false

# Сущность, которая ходит сейчас
var _current_entity: Entity = null


func initialize(entities: Array[Entity]) -> void:
        # Очищаем и перемешиваем
        _turn_order.clear()
        
        # Копируем только действующие сущности
        for entity: Entity in entities:
                _turn_order.append(entity)
        
        # Перемешиваем порядок (случайно)
        _shuffle_turn_order()
        
        _round_number = 0
        _turn_index = 0
        _is_active = false


func _shuffle_turn_order() -> void:
        # Алгоритм Fisher-Yates для перемешивания
        var rng: RandomNumberGenerator = RandomNumberGenerator.new()
        rng.randomize()
        
        for i: int in range(_turn_order.size() - 1, 0, -1):
                var j: int = rng.randi_range(0, i)
                var temp: Entity = _turn_order[i]
                _turn_order[i] = _turn_order[j]
                _turn_order[j] = temp


func start_game() -> void:
        _is_active = true
        _start_round()


func _start_round() -> void:
        _round_number += 1
        _turn_index = 0
        
        emit_signal("round_started", _round_number)
        
        _start_current_turn()


func _start_current_turn() -> void:
        if not _is_active:
                return
        
        if _turn_index >= _turn_order.size():
                # Раунд закончен
                _on_round_finished()
                return
        
        _current_entity = _turn_order[_turn_index]
        emit_signal("turn_started", _current_entity)
        
        # Подписываемся на завершение хода
        if not _current_entity.is_connected("turn_finished", _on_entity_turn_finished):
                _current_entity.connect("turn_finished", _on_entity_turn_finished)
        
        # Запускаем ход сущности
        _current_entity._start_turn()


func _on_entity_turn_finished() -> void:
        emit_signal("turn_finished", _current_entity)
        _turn_index += 1
        
        # Задержка перед следующим ходом
        await get_tree().create_timer(TURN_DELAY).timeout
        _start_current_turn()


func _on_round_finished() -> void:
        emit_signal("round_finished", _round_number)
        
        # Начинаем новый раунд
        call_deferred("_start_round")


# Перезапуск текущего раунда (для отката)
func restart_current_round() -> void:
        _turn_index = 0
        emit_signal("round_started", _round_number)
        _start_current_turn()


# Начать предыдущий раунд (для глобального отката)
func start_previous_round() -> void:
        _round_number -= 1
        _turn_index = 0
        emit_signal("round_started", _round_number)
        _start_current_turn()


func pause() -> void:
        _is_active = false


func resume() -> void:
        _is_active = true


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
