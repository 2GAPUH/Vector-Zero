extends Area2D
class_name Entity

# === СИГНАЛЫ ===
signal turn_finished
signal request_action(action: Action)
signal died(entity: Entity)
signal hp_changed(entity: Entity, old_hp: int, new_hp: int)
signal ap_changed(entity: Entity, old_ap: int, new_ap: int)

# === ПАРАМЕТРЫ ===
# Позиция на сетке
var tile_position: Vector2i = Vector2i.ZERO

# Скорость перемещения (количество клеток за действие)
@export var speed: int = 2

# Здоровье
@export var max_hp: int = 2
var hp: int = 2

# Очки действий
@export var max_ap: int = 1
var current_ap: int = 0

# Базовый урон
@export var base_damage: int = 1

# Флаг: жива ли сущность
var is_alive: bool = true

# Ссылка на уровень
var current_level: Level = null

# Контроллер для AI (null для игрока)
var controller: Controller = null

# Список способностей
var abilities: Array[Ability] = []

# Флаг: сейчас ход этой сущности
var _is_my_turn: bool = false


func _ready() -> void:
	hp = max_hp
	current_ap = max_ap


# === УПРАВЛЕНИЕ ХОДОМ ===

# Начать ход (переопределяется в наследниках)
func _start_turn() -> void:
	if not is_alive:
		emit_signal("turn_finished")
		return
	
	_is_my_turn = true
	_reset_ap()


# Завершить ход
func end_turn() -> void:
	_is_my_turn = false
	emit_signal("turn_finished")


# Проверить, сейчас ли ход этой сущности
func is_my_turn() -> bool:
	return _is_my_turn and is_alive


# === ОЧКИ ДЕЙСТВИЙ ===

# Сбросить AP в начале хода
func _reset_ap() -> void:
	var old_ap: int = current_ap
	current_ap = max_ap
	emit_signal("ap_changed", self, old_ap, current_ap)


# Потратить AP
func spend_ap(amount: int) -> bool:
	if current_ap < amount:
		return false
	
	var old_ap: int = current_ap
	current_ap -= amount
	emit_signal("ap_changed", self, old_ap, current_ap)
	return true


# Проверить, достаточно ли AP
func has_ap(amount: int) -> bool:
	return current_ap >= amount


# === ЗДОРОВЬЕ ===

# Получить урон
func take_damage(amount: int) -> void:
	if not is_alive:
		return
	
	var old_hp: int = hp
	hp = max(0, hp - amount)
	emit_signal("hp_changed", self, old_hp, hp)
	
	if hp <= 0:
		_die()


# Восстановить здоровье
func heal(amount: int) -> void:
	var old_hp: int = hp
	hp = min(max_hp, hp + amount)
	emit_signal("hp_changed", self, old_hp, hp)


# Смерть сущности
func _die() -> void:
	is_alive = false
	emit_signal("died", self)


# === СПОСОБНОСТИ ===

# Получить способность по имени
func get_ability_by_name(ability_name: String) -> Ability:
	for ability: Ability in abilities:
		if ability.ability_name == ability_name:
			return ability
	return null


# Проверить наличие способности
func has_ability(ability_name: String) -> bool:
	return get_ability_by_name(ability_name) != null


# Добавить способность
func add_ability(ability: Ability) -> void:
	if not abilities.has(ability):
		abilities.append(ability)


# === ИНИЦИАЛИЗАЦИЯ ===

# Инициализация сущности на уровне
func setup(level: Level) -> void:
	current_level = level
	tile_position = level.local_to_tile(position)


# === ПЕРЕМЕЩЕНИЕ ===

# Успешное перемещение
func move_success(new_tile_pos: Vector2i) -> void:
	tile_position = new_tile_pos
	
	# Плавная анимация перемещения
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", current_level.tile_to_local(tile_position), 0.2).set_trans(Tween.TRANS_SINE)


# Неудачное перемещение
func move_fail() -> void:
	pass


# === ИНФОРМАЦИЯ ===

# Получить отображаемое имя
func get_display_name() -> String:
	return "Сущность"
