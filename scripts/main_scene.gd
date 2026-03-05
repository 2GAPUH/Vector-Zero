extends Node2D

# Ссылки на узлы
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


func _ready() -> void:
	_setup_managers()
	_setup_entities()
	_connect_signals()
	_start_game()


# Создать и настроить менеджеры
func _setup_managers() -> void:
	# Создаём RoundManager
	round_manager = RoundManager.new()
	add_child(round_manager)
	
	# Создаём HistoryManager
	history_manager = HistoryManager.new()
	history_manager.setup(level)
	level.set_history_manager(history_manager)


# Зарегистрировать все сущности на уровне
func _setup_entities() -> void:
	# Регистрируем героев
	for hero: Entity in heroes:
		level.register_entity(hero, level.local_to_tile(hero.position))
	
	# Регистрируем врагов
	for enemy: Entity in enemies:
		level.register_entity(enemy, level.local_to_tile(enemy.position))


# Подключить сигналы
func _connect_signals() -> void:
	# Сигналы RoundManager
	round_manager.round_started.connect(_on_round_started)
	round_manager.turn_preparing.connect(_on_turn_preparing)
	round_manager.turn_started.connect(_on_turn_started)
	round_manager.turn_finished.connect(_on_turn_finished)
	round_manager.round_finished.connect(_on_round_finished)
	
	# Сигналы UI
	game_ui.end_turn_requested.connect(_on_end_turn_requested)
	game_ui.undo_local_requested.connect(_on_undo_local_requested)
	game_ui.undo_round_start_requested.connect(_on_undo_round_start_requested)
	game_ui.undo_full_round_requested.connect(_on_undo_full_round_requested)


# Начать игру
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


# === ОБРАБОТЧИКИ СИГНАЛОВ ===

func _on_round_started(round_number: int) -> void:
	print("=== Round ", round_number, " started ===")
	game_ui.update_round_text(round_number)
	history_manager.start_new_round(round_number)


func _on_turn_preparing(entity: Entity) -> void:
	print("Turn preparing: ", entity.name)
	
	# Перемещаем камеру к сущности (плавно, если не видна)
	await camera.move_to_entity_async(entity)
	
	# Подтверждаем начало хода
	round_manager.confirm_turn_start()


func _on_turn_started(entity: Entity) -> void:
	print("Turn started: ", entity.name)
	game_ui.update_turn_text(entity)
	game_ui.set_current_turn(round_manager.get_turn_order().find(entity))


func _on_turn_finished(entity: Entity) -> void:
	print("Turn finished: ", entity.name)
	# Увеличиваем индекс хода в истории
	history_manager.advance_turn()


func _on_round_finished(round_number: int) -> void:
	print("=== Round ", round_number, " finished ===")


# === ОБРАБОТЧИК ЗАВЕРШЕНИЯ ХОДА ===

func _on_end_turn_requested() -> void:
	# Завершить ход текущего героя
	var current: Entity = round_manager.get_current_entity()
	if current is Hero:
		current.end_turn()


# === ОБРАБОТЧИКИ ОТКАТОВ ===

func _on_undo_local_requested() -> void:
	# Локальный откат - только в ход героя
	if not round_manager.is_hero_turn():
		return
	
	var current_hero: Entity = round_manager.get_current_entity()
	if history_manager.can_undo_last_action(current_hero):
		history_manager.undo_last_action(current_hero)
		game_ui.show_message("Действие отменено")


func _on_undo_round_start_requested() -> void:
	# Промежуточный откат - на начало текущего раунда
	if history_manager.can_undo_to_round_start():
		history_manager.undo_to_round_start()
		round_manager.restart_current_round()
		game_ui.show_message("Возврат на начало раунда")


func _on_undo_full_round_requested() -> void:
	# Глобальный откат - на один раунд назад
	if history_manager.can_undo_full_round():
		# Сначала откатываем текущий раунд
		history_manager.undo_to_round_start()
		# Затем предыдущий раунд
		var previous_round: int = history_manager.get_current_round() - 1
		if previous_round >= 1:
			# Откатываем историю
			history_manager.undo_full_round()
			# Перезапускаем предыдущий раунд
			round_manager.start_previous_round()
			game_ui.show_message("Возврат на раунд назад")
