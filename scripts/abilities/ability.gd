class_name Ability
extends RefCounted

# === БАЗОВЫЙ КЛАСС СПОСОБНОСТИ ===

# Название и описание
var name: String = "Способность"
var description: String = ""

# Стоимость в очках действий
var cost: int = 0

# Владелец способности
var entity: Entity = null


# === ПРОВЕРКА ВОЗМОЖНОСТИ ИСПОЛЬЗОВАНИЯ ===
func can_use() -> bool:
	# Базовые проверки
	if entity == null:
		return false
	
	if not entity.is_alive:
		return false
	
	# Проверяем AP
	if entity.current_ap < cost:
		return false
	
	return true


# === ПОЛУЧИТЬ ВСЕ ВАЛИДНЫЕ ЦЕЛИ ===
# Переопределяется в наследниках
func get_valid_targets() -> Array[Vector2i]:
	return []


# === ПРОВЕРКА ВАЛИДНОСТИ ЦЕЛИ ===
func is_valid_target(target: Variant) -> bool:
	if target is Vector2i:
		return target in get_valid_targets()
	return false


# === ВЫПОЛНИТЬ СПОСОБНОСТЬ ===
# Переопределяется в наследниках
# Возвращает true если успешно
func execute(target: Variant) -> bool:
	return false


# === ПОЛУЧИТЬ ДАЛЬНОСТЬ ===
func get_range() -> int:
	return 0


# === ПОЛУЧИТЬ ЦВЕТ ПОДСВЕТКИ ===
func get_highlight_color() -> Color:
	return Color.WHITE
