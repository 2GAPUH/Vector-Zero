extends Node2D

# === ССЫЛКИ НА УЗЛЫ ===
@onready var level: Level = $Level
@onready var camera: CameraController = $Camera
@onready var game_ui: Control = $CanvasLayer/GameUI

# Герои
@onready var heroes: Array[Entity] = [$Hero1, $Hero2]

# Враги
@onready var enemies: Array[Entity] = [$Enemy1, $Enemy2]

# Менеджеры
var round_manager: RoundManager = null
var history_manager: HistoryManager = null

# Подсветка клеток
var highlight_layer: HighlightLayer = null


func _ready() -> void:
	_setup_managers()
	_setup_entities()
	_connect_signals()
	_setup_highlight_layer()
	_start_game()


# === ИНИЦИАЛИЗАЦИЯ ===

func _setup_managers() -> void:
	# Создаём RoundManager
	round_manager = RoundManager.new()
	add_child(round_manager)
	
	# Создаём HistoryManager
	history_manager = HistoryManager.new()
	history_manager.setup(level)
	level.set_history_manager(history_manager)


func _setup_entities() -> void:
	# Регистрируем героев
	for hero: Entity in heroes:
		level.register_entity(hero, level.local_to_tile(hero.position))
	
	# Регистрируем врагов
	for enemy: Entity in enemies:
		level.register_entity(enemy, level.local_to_tile(enemy.position))


func _connect_signals() -> void:
	# Сигналы RoundManager
	round_manager.round_started.connect(_on_round_started)
	round_manager.turn_preparing.connect(_on_turn_preparing)
	round_manager.turn_started.connect(_on_turn_started)
	round_manager.turn_finished.connect(_on_turn_finished)
	round_manager.round_finished.connect(_on_round_finished)
	round_manager.entity_died.connect(_on_entity_died)
	
	# Сигналы UI
	game_ui.end_turn_requested.connect(_on_end_turn_requested)
	game_ui.ability_selected.connect(_on_ability_selected)
	game_ui.undo_local_requested.connect(_on_undo_local_requested)
	game_ui.undo_round_start_requested.connect(_on_undo_round_start_requested)
	game_ui.undo_full_round_requested.connect(_on_undo_full_round_requested)


func _setup_highlight_layer() -> void:
	highlight_layer = HighlightLayer.new()
	highlight_layer.name = "HighlightLayer"
	highlight_layer.z_index = 10
	highlight_layer.set_level(level)
	add_child(highlight_layer)


func _start_game() -> void:
	# Собираем все сущности
	var all_entities: Array[Entity] = []
	all_entities.append_array(heroes)
	all_entities.append_array(enemies)
	
	# Инициализируем RoundManager
	round_manager.initialize(all_entities)
	
	# Передаём порядок ходов в UI
	game_ui.set_turn_order(round_manager.get_turn_order())
	
	# Перемещаем камеру к первому герою
	if heroes.size() > 0:
		camera.teleport_to_entity(heroes[0])
	
	round_manager.start_game()


# === ПОДСВЕТКА КЛЕТОК ===

func _clear_highlight() -> void:
	highlight_layer.clear_cells()


func _highlight_valid_targets(targets: Array[Vector2i], type: String = "move") -> void:
	highlight_layer.set_cells(targets, type)


# Обновление UI способностей при смене хода
func _update_ability_ui() -> void:
	var current: Entity = round_manager.get_current_entity()
	if current is Hero:
		game_ui.update_abilities(current.get_available_abilities())
	else:
		game_ui.clear_abilities()


# === ОБРАБОТЧИКИ СИГНАЛОВ ===

func _on_round_started(round_number: int) -> void:
	print("=== Round ", round_number, " started ===")
	game_ui.update_round_text(round_number)
	history_manager.start_new_round(round_number)


func _on_turn_preparing(entity: Entity) -> void:
	print("Turn preparing: ", entity.name)
	
	# Устанавливаем цель для камеры
	camera.set_target(entity)
	
	# Перемещаем камеру к сущности (плавно, если не видна)
	await camera.move_to_entity_async(entity)
	
	# Подтверждаем начало хода
	round_manager.confirm_turn_start()


func _on_turn_started(entity: Entity) -> void:
	print("Turn started: ", entity.name)
	game_ui.update_turn_text(entity)
	game_ui.set_current_turn(round_manager.get_turn_order().find(entity))
	
	# Обновляем UI способностей
	_update_ability_ui()
	
	# Если это герой - показываем доступные клетки для перемещения
	if entity is Hero:
		var move_ability: Ability = entity.get_ability_by_name("Перемещение")
		if move_ability != null:
			var targets: Array[Vector2i] = move_ability.get_valid_targets(entity, level)
			_highlight_valid_targets(targets, "move")


func _on_turn_finished(entity: Entity) -> void:
	print("Turn finished: ", entity.name)
	_clear_highlight()
	history_manager.advance_turn()


func _on_round_finished(round_number: int) -> void:
	print("=== Round ", round_number, " finished ===")


func _on_entity_died(entity: Entity) -> void:
	print("Entity died event: ", entity.name)
	
	# Обновляем UI очередности
	game_ui.set_turn_order(round_manager.get_turn_order())
	
	# Удаляем из списков
	heroes.erase(entity)
	enemies.erase(entity)


# === ОБРАБОТЧИК ЗАВЕРШЕНИЯ ХОДА ===

func _on_end_turn_requested() -> void:
	var current: Entity = round_manager.get_current_entity()
	if current is Hero:
		current.end_turn()


# === ОБРАБОТЧИК ВЫБОРА СПОСОБНОСТИ ===

func _on_ability_selected(ability_name: String) -> void:
	var current: Entity = round_manager.get_current_entity()
	if not current is Hero:
		return
	
	var hero: Hero = current as Hero
	
	if hero.select_ability(ability_name):
		# Получаем валидные цели и подсвечиваем
		var targets: Array[Vector2i] = hero.get_valid_targets_for_selected()
		var type: String = "move"
		if ability_name == "Атака":
			type = "attack"
		_highlight_valid_targets(targets, type)
		game_ui.show_message("Выберите цель: " + ability_name)


# === ОБРАБОТЧИКИ ОТКАТОВ ===

func _on_undo_local_requested() -> void:
	if not round_manager.is_hero_turn():
		return
	
	var current_hero: Entity = round_manager.get_current_entity()
	if history_manager.can_undo_last_action(current_hero):
		history_manager.undo_last_action(current_hero)
		game_ui.show_message("Действие отменено")


func _on_undo_round_start_requested() -> void:
	if history_manager.can_undo_to_round_start():
		history_manager.undo_to_round_start()
		round_manager.restart_current_round()
		game_ui.show_message("Возврат на начало раунда")


func _on_undo_full_round_requested() -> void:
	if history_manager.can_undo_full_round():
		history_manager.undo_to_round_start()
		var previous_round: int = history_manager.get_current_round() - 1
		if previous_round >= 1:
			history_manager.undo_full_round()
			round_manager.start_previous_round()
			game_ui.show_message("Возврат на раунд назад")
