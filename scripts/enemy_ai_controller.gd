class_name EnemyAIController
extends Controller

# === AI КОНТРОЛЛЕР ВРАГОВ ===
# Принимает решения на основе приоритетов:
# 1. Атака игрока (если рядом)
# 2. Рывок к игроку (если далеко)
# 3. Обычное перемещение к игроку
# 4. Атака препятствия (если путь заблокирован)


func _init(actor: Entity) -> void:
	super(actor)


# === ПОЛУЧИТЬ СЛЕДУЮЩЕЕ ДЕЙСТВИЕ ===
func get_next_action() -> Action:
	if entity == null or not entity.is_alive:
		return null
	
	var level: Level = entity.current_level
	if level == null:
		return null
	
	# Находим ближайшего героя
	var hero_pos: Vector2i = level.get_nearest_hero_position(entity.tile_position)
	if hero_pos == Vector2i.ZERO:
		return null  # Героев нет
	
	# 1. ПРОВЕРЯЕМ: игрок рядом? -> АТАКА
	var attack_action: Action = _try_attack_hero(hero_pos)
	if attack_action != null:
		return attack_action
	
	# 2. ПРОВЕРЯЕМ: можем ли переместиться к игроку?
	var path_result: Dictionary = _find_path_to_target(hero_pos)
	
	# Путь есть — выбираем способ перемещения
	if path_result["path"].size() > 0:
		var path: Array[Vector2i] = path_result["path"]
		var distance: int = path.size()
		
		# Обычное перемещение (2 клетки, бесплатно)
		if distance <= entity.move_pool and entity.move_pool > 0:
			return _create_move_action(path)
		
		# Рывок (6 клеток, 1 AP) — если есть AP
		if entity.current_ap >= 1 and distance <= entity.base_move_pool * 3:
			return _create_dash_action(path)
		
		# Просто идём насколько можем
		if entity.move_pool > 0:
			var partial_path: Array[Vector2i] = _slice_path(path, entity.move_pool)
			return _create_move_action(partial_path)
	
	# 3. ПУТЬ ЗАБЛОКИРОВАН — атакуем препятствие
	var blocking_entity: Entity = path_result["blocking_entity"]
	if blocking_entity != null and blocking_entity is Obstacle:
		return _create_attack_obstacle_action(blocking_entity)
	
	# Не можем ничего сделать
	return null


# === ЕСТЬ ЛИ ЕЩЁ ДЕЙСТВИЯ ===
func has_more_actions() -> bool:
	# У врага 1 AP, значит одно действие за ход
	return false


# === СБРОС СОСТОЯНИЯ ===
func reset() -> void:
	pass


# === ПОПЫТКА АТАКОВАТЬ ГЕРОЯ ===
func _try_attack_hero(hero_pos: Vector2i) -> Action:
	var distance: int = _get_manhattan_distance(entity.tile_position, hero_pos)
	
	# Герой не рядом
	if distance != 1:
		return null
	
	# Проверяем есть ли способность атаки
	var attack_ability: Ability = _get_attack_ability()
	if attack_ability == null:
		return null
	
	# Проверяем, можем ли атаковать
	if not attack_ability.can_use():
		return null
	
	# Проверяем, что герой в валидных целях
	if not attack_ability.is_valid_target(hero_pos):
		return null
	
	# Атакуем!
	return AttackAction.new(entity, entity.current_level.get_entity_at(hero_pos), 1, hero_pos)


# === НАЙТИ ПУТЬ К ЦЕЛИ ===
func _find_path_to_target(target_pos: Vector2i) -> Dictionary:
	var pathfinder: Pathfinder = Pathfinder.new()
	return pathfinder.find_path_with_obstacle(entity.tile_position, target_pos, entity.current_level)


# === СОЗДАТЬ ДЕЙСТВИЕ ПЕРЕМЕЩЕНИЯ ===
func _create_move_action(path: Array[Vector2i]) -> Action:
	return MoveAction.new(entity, path)


# === СОЗДАТЬ ДЕЙСТВИЕ РЫВКА ===
func _create_dash_action(path: Array[Vector2i]) -> Action:
	# Тратим AP
	entity.spend_ap(1)
	
	# Устанавливаем новый запас перемещения
	var dash_pool: int = entity.base_move_pool * 3
	entity.move_pool = dash_pool - path.size()
	
	return MoveAction.new(entity, path)


# === СОЗДАТЬ ДЕЙСТВИЕ АТАКИ ПРЕПЯТСТВИЯ ===
func _create_attack_obstacle_action(obstacle: Obstacle) -> Action:
	# Находим направление к препятствию
	var direction: Vector2i = obstacle.tile_position - entity.tile_position
	
	# Тратим AP
	entity.spend_ap(1)
	
	return AttackAction.new(entity, obstacle, 1, obstacle.tile_position)


# === ОБРЕЗАТЬ ПУТЬ ДО ОПРЕДЕЛЁННОЙ ДЛИНЫ ===
func _slice_path(path: Array[Vector2i], max_length: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for i: int in range(mini(path.size(), max_length)):
		result.append(path[i])
	return result


# === МАНХЭТТЕНСКОЕ РАССТОЯНИЕ ===
func _get_manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# === ПОЛУЧИТЬ СПОСОБНОСТЬ АТАКИ ===
func _get_attack_ability() -> Ability:
	for ability: Ability in entity.abilities:
		if ability is AttackAbility:
			return ability
	return null


# === ПОЛУЧИТЬ СПОСОБНОСТЬ ПЕРЕМЕЩЕНИЯ ===
func _get_move_ability() -> Ability:
	for ability: Ability in entity.abilities:
		if ability is MoveAbility:
			return ability
	return null
