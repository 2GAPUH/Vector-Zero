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

# Текущее действие перемещения (для отслеживания завершения анимации)
var _current_move_action: MoveAction = null


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
		
		# Сигнал завершения действия от уровня
		level.action_completed.connect(_on_action_completed)


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


# Обновление UI способностей и подсветки при смене хода
func _update_ability_ui(hero: Hero) -> void:
		game_ui.update_abilities(hero)


# Обновить подсветку после действия
func _update_highlight_after_action() -> void:
		var current: Entity = round_manager.get_current_entity()
		if current is Hero:
				var hero: Hero = current as Hero
				
				# Обновляем UI
				game_ui.update_abilities(hero)
				
				# Обновляем подсветку доступных клеток
				var move_ability: Ability = hero.get_ability_by_name("Перемещение")
				if move_ability != null and hero.move_budget > 0:
						var targets: Array[Vector2i] = move_ability.get_valid_targets(hero, level)
						_highlight_valid_targets(targets, "move")
				else:
						_clear_highlight()


# === ОБРАБОТЧИКИ СИГНАЛОВ ===

func _on_round_started(round_number: int) -> void:
		print("=== Round ", round_number, " started ===")
		game_ui.update_round_text(round_number)
		history_manager.start_new_round(round_number)


func _on_turn_preparing(entity: Entity) -> void:
		print("Turn preparing: ", entity.name)
		
		# Устанавливаем цель для камеры
		camera.set_target(entity)
		
		# Включаем слежение для врагов, отключаем для героев
		if entity is Hero:
				camera.set_follow_enabled(false)
		else:
				camera.set_follow_enabled(true)
		
		# Перемещаем камеру к сущности (плавно, если не видна)
		await camera.move_to_entity_async(entity)
		
		# Подтверждаем начало хода
		round_manager.confirm_turn_start()


func _on_turn_started(entity: Entity) -> void:
		print("Turn started: ", entity.name)
		game_ui.update_turn_text(entity)
		game_ui.set_current_turn(round_manager.get_turn_order().find(entity))
		
		# Если это герой - обновляем UI
		if entity is Hero:
				var hero: Hero = entity as Hero
				_update_ability_ui(hero)
				
				# Показываем доступные клетки для перемещения
				var move_ability: Ability = hero.get_ability_by_name("Перемещение")
				if move_ability != null:
						var targets: Array[Vector2i] = move_ability.get_valid_targets(hero, level)
						_highlight_valid_targets(targets, "move")
		else:
				game_ui.clear_abilities()


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
		
		# Рывок применяется мгновенно
		if ability_name == "Рывок":
				var dash_ability: Ability = hero.get_ability_by_name("Рывок")
				if dash_ability != null and dash_ability.can_use(hero, level):
						# Создаём и выполняем действие напрямую
						var action: Action = dash_ability.create_action(hero, null, level)
						if action != null:
								var success: bool = action.execute(level)
								if success:
										# Записываем в историю
										if history_manager != null:
												history_manager.record_action(hero, action)
										# Обновляем подсветку после рывка
										_update_highlight_after_action()
										game_ui.show_message("Рывок! Запас движения: " + str(hero.move_budget) + "/" + str(hero.max_move_budget))
				return
		
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
				_update_highlight_after_action()


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


# === ОБРАБОТЧИК ЗАВЕРШЕНИЯ ДЕЙСТВИЯ ===

func _on_action_completed() -> void:
		# Обновляем подсветку и UI после завершения действия
		_update_highlight_after_action()
