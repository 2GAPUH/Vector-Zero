class_name AIController
extends Controller

# Кэшированные данные для принятия решений
var _last_known_hero_pos: Vector2i = Vector2i.ZERO


func _init(actor: Entity) -> void:
	super(actor)


# Получить следующее действие
func get_next_action() -> Action:
	if not entity.is_alive or entity.current_level == null:
		return null
	
	var level: Level = entity.current_level
	var my_pos: Vector2i = entity.tile_position
	
	# 1. Находим ближайшего героя
	var target_hero: Hero = level.get_nearest_hero(my_pos)
	
	if target_hero == null:
		return null
	
	_last_known_hero_pos = target_hero.tile_position
	
	# 2. Проверяем: герой рядом? -> Атака
	if _is_adjacent(my_pos, target_hero.tile_position):
		return _create_attack_action(level, target_hero.tile_position)
	
	# 3. Проверяем: есть ли препятствие на пути? -> Атака препятствия
	var obstacle_action: Action = _check_and_attack_obstacle(level, my_pos, target_hero.tile_position)
	if obstacle_action != null:
		return obstacle_action
	
	# 4. Рассчитываем расстояние до героя
	var distance: int = _manhattan_distance(my_pos, target_hero.tile_position)
	
	# 5. Выбираем способ перемещения
	if distance <= 2:
		# Близко - обычное перемещение
		return _create_move_action(level, target_hero.tile_position, 2)
	elif distance <= 6 and entity.has_ap(1):
		# Далеко и есть AP - рывок
		return _create_dash_action(level, target_hero.tile_position)
	else:
		# Иначе обычное перемещение
		return _create_move_action(level, target_hero.tile_position, 2)


# Проверить, есть ли препятствие на пути к цели
func _check_and_attack_obstacle(level: Level, my_pos: Vector2i, target_pos: Vector2i) -> Action:
	# Проверяем соседние клетки в направлении цели
	var dir_to_target: Vector2i = _get_direction_to(my_pos, target_pos)
	var check_pos: Vector2i = my_pos + dir_to_target
	
	if dir_to_target == Vector2i.ZERO:
		return null
	
	var entity_at_pos: Entity = level.get_entity_at(check_pos)
	if entity_at_pos is Obstacle:
		# Атакуем препятствие
		if entity.has_ap(1):
			return _create_attack_action(level, check_pos)
	
	return null


# Создать действие атаки
func _create_attack_action(level: Level, target_pos: Vector2i) -> Action:
	var attack_ability: AttackAbility = entity.get_ability_by_name("Атака") as AttackAbility
	if attack_ability == null:
		return null
	
	if not entity.has_ap(attack_ability.ap_cost):
		return null
	
	return attack_ability.create_action(entity, target_pos, level)


# Создать действие перемещения
func _create_move_action(level: Level, target_pos: Vector2i, _max_range: int) -> Action:
	var move_ability: MoveAbility = entity.get_ability_by_name("Перемещение") as MoveAbility
	if move_ability == null:
		return null
	
	# Получаем валидные цели
	var valid_targets: Array[Vector2i] = move_ability.get_valid_targets(entity, level)
	
	if valid_targets.is_empty():
		return null
	
	# Находим ближайшую к цели точку из доступных
	var best_target: Vector2i = _find_best_approach_target(valid_targets, target_pos)
	
	return move_ability.create_action(entity, best_target, level)


# Создать действие рывка
func _create_dash_action(level: Level, target_pos: Vector2i) -> Action:
	var dash_ability: DashAbility = entity.get_ability_by_name("Рывок") as DashAbility
	if dash_ability == null:
		return null
	
	if not entity.has_ap(dash_ability.ap_cost):
		return null
	
	# Получаем валидные цели
	var valid_targets: Array[Vector2i] = dash_ability.get_valid_targets(entity, level)
	
	if valid_targets.is_empty():
		return null
	
	# Находим ближайшую к цели точку из доступных
	var best_target: Vector2i = _find_best_approach_target(valid_targets, target_pos)
	
	return dash_ability.create_action(entity, best_target, level)


# Найти лучшую точку приближения к цели
func _find_best_approach_target(valid_targets: Array[Vector2i], target_pos: Vector2i) -> Vector2i:
	var best: Vector2i = valid_targets[0]
	var best_dist: int = _manhattan_distance(best, target_pos)
	
	for pos: Vector2i in valid_targets:
		var dist: int = _manhattan_distance(pos, target_pos)
		if dist < best_dist:
			best_dist = dist
			best = pos
	
	return best


# Проверить, является ли клетка соседней
func _is_adjacent(pos1: Vector2i, pos2: Vector2i) -> bool:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y) == 1


# Манхэттенское расстояние
func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


# Получить направление к цели
func _get_direction_to(from: Vector2i, to: Vector2i) -> Vector2i:
	var diff: Vector2i = to - from
	# Приоритет по X или Y
	if diff.x != 0:
		return Vector2i(sign(diff.x), 0)
	elif diff.y != 0:
		return Vector2i(0, sign(diff.y))
	return Vector2i.ZERO
