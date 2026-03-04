extends Area2D
class_name Entity

# === СИГНАЛЫ ===
signal turn_finished
signal request_action(action: Action)
signal hp_changed(current: int, maximum: int)
signal ap_changed(current: int, maximum: int)
signal move_pool_changed(current: int)
signal damaged(amount: int, source: Entity)
signal died(killer: Entity)

# === ПАРАМЕТТРЫ ===
# Здоровье
@export var max_hp: int = 2
var current_hp: int = 2

# Очки действий
@export var max_ap: int = 1
var current_ap: int = 0

# Запас перемещения
@export var base_move_pool: int = 2
var move_pool: int = 0

# Позиция на сетке
var tile_position: Vector2i = Vector2i.ZERO

# Ссылка на уровень
var current_level: Level = null

# Контроллер для AI (null для игрока)
var controller: Controller = null

# Способности
var abilities: Array[Ability] = []

# Жив ли?
var is_alive: bool = true


func _ready() -> void:
	current_hp = max_hp
	current_ap = max_ap
	move_pool = base_move_pool


# === НАЧАЛО ХОДА ===
func _start_turn() -> void:
	if not is_alive:
		emit_signal("turn_finished")
		return
	
	# Восстанавливаем AP и запас перемещения
	current_ap = max_ap
	move_pool = base_move_pool
	
	emit_signal("ap_changed", current_ap, max_ap)
	emit_signal("move_pool_changed", move_pool)


# === ИНИЦИАЛИЗАЦИЯ ===
func setup(level: Level) -> void:
	current_level = level
	tile_position = level.local_to_tile(position)


# === ДОБАВЛЕНИЕ СПОСОБНОСТЕЙ ===
func add_ability(ability: Ability) -> void:
	ability.entity = self
	abilities.append(ability)


# === ПРОВЕРКА AP ===
func can_afford(ap_cost: int) -> bool:
	return current_ap >= ap_cost


# === ТРАТА AP ===
func spend_ap(amount: int) -> void:
	current_ap -= amount
	if current_ap < 0:
		current_ap = 0
	emit_signal("ap_changed", current_ap, max_ap)


# === ЗАПАС ПЕРЕМЕЩЕНИЯ ===
func has_move_pool(amount: int) -> bool:
	return move_pool >= amount


func spend_move_pool(amount: int) -> void:
	move_pool -= amount
	if move_pool < 0:
		move_pool = 0
	emit_signal("move_pool_changed", move_pool)


# === ПОЛУЧЕНИЕ УРОНА ===
func take_damage(amount: int, source: Entity) -> void:
	if not is_alive:
		return
	
	current_hp -= amount
	emit_signal("damaged", amount, source)
	emit_signal("hp_changed", current_hp, max_hp)
	
	if current_hp <= 0:
		die(source)


# === СМЕРТЬ ===
func die(killer: Entity) -> void:
	is_alive = false
	emit_signal("died", killer)
	
	# Создаём труп на месте смерти
	if current_level != null:
		current_level.spawn_corpse(self)
	
	# Удаляем сущность
	queue_free()


# === ПЕРЕМЕЩЕНИЕ (последовательное по пути) ===
func follow_path(path: Array[Vector2i]) -> void:
	if path.is_empty():
		return
	
	# Обновляем позицию на уровне
	var old_pos: Vector2i = tile_position
	var new_pos: Vector2i = path[path.size() - 1]
	current_level.update_entity_position(old_pos, new_pos, self)
	
	# Последовательно перемещаемся по клеткам
	for step: Vector2i in path:
		await _move_one_cell(step)


func _move_one_cell(target_pos: Vector2i) -> void:
	tile_position = target_pos
	
	# Анимация перемещения
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", current_level.tile_to_local(target_pos), 0.15).set_trans(Tween.TRANS_SINE)
	
	await tween.finished


# === УСПЕШНОЕ ПЕРЕМЕЩЕНИЕ (для обратной совместимости) ===
func move_success(direction: Vector2i) -> void:
	tile_position += direction
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", current_level.tile_to_local(tile_position), 0.3).set_trans(Tween.TRANS_SINE)


# === НЕУДАЧНОЕ ПЕРЕМЕЩЕНИЕ ===
func move_fail() -> void:
	print("Move failed")


# === ЗАВЕРШИТЬ ХОД ===
func end_turn() -> void:
	emit_signal("turn_finished")
