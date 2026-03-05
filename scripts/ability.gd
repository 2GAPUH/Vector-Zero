class_name Ability
extends RefCounted

# === ПАРАМЕТРЫ ===
# Название способности
var ability_name: String = "Способность"

# Описание
var description: String = ""

# Стоимость в очках действий
var ap_cost: int = 1

# Дальность действия
var range: int = 1

# Урон (если применимо)
var damage: int = 1

# Тип цели
enum TargetType {
	NONE,       # Без цели (самонакладываемая)
	TILE,       # Клетка
	DIRECTION,  # Направление (для атаки)
	ENTITY      # Сущность
}
var target_type: TargetType = TargetType.TILE


# === МЕТОДЫ ===

# Проверить, можно ли использовать способность
func can_use(entity: Entity, level: Level) -> bool:
	# Базовая проверка: достаточно ли AP
	if not entity.has_ap(ap_cost):
		return false
	
	# Проверка: жива ли сущность
	if not entity.is_alive:
		return false
	
	return true


# Получить список валидных целей
func get_valid_targets(entity: Entity, level: Level) -> Array[Vector2i]:
	return []


# Создать действие для выполнения способности
# Возвращает Action или null если не может быть выполнено
func create_action(entity: Entity, target: Variant, level: Level) -> Action:
	return null


# Получить направление от одной клетки к другой
func get_direction_to(from: Vector2i, to: Vector2i) -> Vector2i:
	var diff: Vector2i = to - from
	return Vector2i(sign(diff.x), sign(diff.y))


# Рассчитать манхэттенское расстояние
func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)
