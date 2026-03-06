class_name Controller
extends RefCounted

# Базовый класс для AI контроллеров
# Наследники реализуют логику принятия решений

var entity: Entity


func _init(actor: Entity) -> void:
	entity = actor


# Получить следующее действие для выполнения
# Переопределяется в наследниках
func get_next_action() -> Action:
	return null


# Проверить, есть ли ещё действия в этом ходу
func has_more_actions() -> bool:
	return false


# Сбросить состояние (вызывается при начале нового хода)
func reset() -> void:
	pass
