extends Node2D

# === ГЛАВНАЯ СЦЕНА ===

# Ссылки на узлы
@onready var level: Level = $Level
@onready var camera: Camera2D = $Camera
@onready var game_ui: GameUI = $CanvasLayer/GameUI

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


# === СОЗДАТЬ И НАСТРОИТЬ МЕНЕДЖЕРЫ ===
func _setup_managers() -> void:
		# Создаём RoundManager
		round_manager = RoundManager.new()
		add_child(round_manager)
		
		# Создаём HistoryManager
		history_manager = HistoryManager.new()
		history_manager.setup(level)
		level.set_history_manager(history_manager)


# === ЗАРЕГИСТРИРОВАТЬ СУЩНОСТИ ===
func _setup_entities() -> void:
		# Регистрируем героев
		for hero: Entity in heroes:
				if hero.is_alive:
						level.register_entity(hero, level.local_to_tile(hero.position))
		
		# Регистрируем врагов
		for enemy: Entity in enemies:
				if enemy.is_alive:
						level.register_entity(enemy, level.local_to_tile(enemy.position))


# === ПОДКЛЮЧИТЬ СИГНАЛЫ ===
func _connect_signals() -> void:
		# Сигналы RoundManager
		round_manager.round_started.connect(_on_round_started)
		round_manager.turn_preparing.connect(_on_turn_preparing)
		round_manager.turn_started.connect(_on_turn_started)
		round_manager.turn_finished.connect(_on_turn_finished)
		round_manager.round_finished.connect(_on_round_finished)
		
		# Сигналы UI
		if game_ui:
				game_ui.end_turn_requested.connect(_on_end_turn_requested)
				game_ui.undo_local_requested.connect(_on_undo_local_requested)
				game_ui.undo_round_start_requested.connect(_on_undo_round_start_requested)
				game_ui.undo_full_round_requested.connect(_on_undo_full_round_requested)
				
				# Сигналы панели способностей
				if game_ui.has_node("AbilitiesPanel"):
						var abilities_panel: AbilitiesPanel = game_ui.get_node("AbilitiesPanel")
						abilities_panel.ability_selected.connect(_on_ability_selected)
						abilities_panel.end_turn_requested.connect(_on_end_turn_requested)


# === НАЧАТЬ ИГРУ ===
func _start_game() -> void:
		# Собираем все живые сущности
		var all_entities: Array[Entity] = []
		
		for hero: Entity in heroes:
				if hero.is_alive:
						all_entities.append(hero)
		
		for enemy: Entity in enemies:
				if enemy.is_alive:
						all_entities.append(enemy)
		
		# Инициализируем RoundManager
		round_manager.initialize(all_entities)
		
		# Передаём порядок ходов в UI
		if game_ui:
				game_ui.set_turn_order(round_manager.get_turn_order())
		
		# Перемещаем камеру к первому герою
		if heroes.size() > 0 and heroes[0].is_alive:
				_center_camera_on(heroes[0])
		
		round_manager.start_game()


# === ОБРАБОТЧИКИ СИГНАЛОВ ===

func _on_round_started(round_number: int) -> void:
		print("=== Раунд ", round_number, " начат ===")
		
		if game_ui:
				game_ui.update_round_text(round_number)
		
		history_manager.start_new_round(round_number)


func _on_turn_preparing(entity: Entity) -> void:
		print("Подготовка хода: ", entity.name)
		
		# Центрируем камеру на сущности
		_center_camera_on(entity)
		
		# Подтверждаем начало хода
		round_manager.confirm_turn_start()


func _on_turn_started(entity: Entity) -> void:
		print("Ход начат: ", entity.name)
		
		if game_ui:
				game_ui.update_turn_text(entity)
				game_ui.set_current_turn(round_manager.get_turn_order().find(entity))
				
				# Настраиваем панель способностей для героя
				if entity is Hero:
						game_ui.setup_abilities_panel(entity)


func _on_turn_finished(entity: Entity) -> void:
		print("Ход завершён: ", entity.name)
		
		# Очищаем подсветку
		level.clear_highlight()
		
		# Увеличиваем индекс хода в истории
		history_manager.advance_turn()


func _on_round_finished(round_number: int) -> void:
		print("=== Раунд ", round_number, " завершён ===")


# === ОБРАБОТЧИК ЗАВЕРШЕНИЯ ХОДА ===
func _on_end_turn_requested() -> void:
		var current: Entity = round_manager.get_current_entity()
		if current is Hero:
				current.end_turn()


# === ОБРАБОТЧИК ВЫБОРА СПОСОБНОСТИ ===
func _on_ability_selected(ability: Ability) -> void:
		var current: Entity = round_manager.get_current_entity()
		if current is Hero:
				current.select_ability(ability)
				
				# Обновляем UI панели
				if game_ui and game_ui.has_node("AbilitiesPanel"):
						var abilities_panel: AbilitiesPanel = game_ui.get_node("AbilitiesPanel")
						abilities_panel.set_selected_ability(ability)


# === ОБРАБОТЧИКИ ОТКАТОВ ===

func _on_undo_local_requested() -> void:
		if not round_manager.is_hero_turn():
				return
		
		var current_hero: Entity = round_manager.get_current_entity()
		if history_manager.can_undo_last_action(current_hero):
				history_manager.undo_last_action(current_hero)
				if game_ui:
						game_ui.show_message("Действие отменено")


func _on_undo_round_start_requested() -> void:
		if history_manager.can_undo_to_round_start():
				history_manager.undo_to_round_start()
				round_manager.restart_current_round()
				if game_ui:
						game_ui.show_message("Возврат на начало раунда")


func _on_undo_full_round_requested() -> void:
		if history_manager.can_undo_full_round():
				history_manager.undo_to_round_start()
				var previous_round: int = history_manager.get_current_round() - 1
				if previous_round >= 1:
						history_manager.undo_full_round()
						round_manager.start_previous_round()
						if game_ui:
								game_ui.show_message("Возврат на раунд назад")


# === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===

func _center_camera_on(entity: Entity) -> void:
		if camera and entity:
				camera.global_position = entity.global_position
