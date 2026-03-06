extends Control

# === СИГНАЛЫ ===
signal end_turn_requested
signal ability_selected(ability_name: String)
signal undo_local_requested
signal undo_round_start_requested
signal undo_full_round_requested

# === ССЫЛКИ НА ЭЛЕМЕНТЫ UI ===
@onready var round_label: Label = $VBoxContainer/InfoContainer/RoundLabel
@onready var turn_label: Label = $VBoxContainer/InfoContainer/TurnLabel
@onready var move_budget_label: Label = $VBoxContainer/InfoContainer/MoveBudgetLabel
@onready var turn_order_container: HBoxContainer = $VBoxContainer/TurnOrderContainer
@onready var message_label: Label = $VBoxContainer/MessageContainer/MessageLabel
@onready var ability_container: HBoxContainer = $VBoxContainer/AbilityContainer

# === ПЕРЕМЕННЫЕ ===
var _turn_order: Array[Entity] = []
var _current_turn_index: int = 0


func _ready() -> void:
		_connect_buttons()


func _connect_buttons() -> void:
		$VBoxContainer/ButtonContainer/EndTurnButton.pressed.connect(_on_end_turn_pressed)
		$VBoxContainer/ButtonContainer/UndoLocalButton.pressed.connect(_on_undo_local_pressed)
		$VBoxContainer/ButtonContainer/UndoRoundStartButton.pressed.connect(_on_undo_round_start_pressed)
		$VBoxContainer/ButtonContainer/UndoFullRoundButton.pressed.connect(_on_undo_full_round_pressed)


# === ОЧЕРЕДНОСТЬ ХОДОВ ===

func set_turn_order(entities: Array[Entity]) -> void:
		_turn_order = entities
		_rebuild_turn_order_ui()


func _rebuild_turn_order_ui() -> void:
		# Удаляем старые элементы
		for child: Node in turn_order_container.get_children():
				child.queue_free()
		
		# Создаём новые элементы
		for i: int in range(_turn_order.size()):
				var entity: Entity = _turn_order[i]
				var label: Label = Label.new()
				label.text = entity.get_display_name()
				
				# Выделяем текущий ход
				if i == _current_turn_index:
						label.modulate = Color.YELLOW
				else:
						label.modulate = Color.WHITE
				
				turn_order_container.add_child(label)


func set_current_turn(index: int) -> void:
		_current_turn_index = index
		_rebuild_turn_order_ui()


# === ИНФОРМАЦИЯ ===

func update_round_text(round_number: int) -> void:
		round_label.text = "Раунд: " + str(round_number)


func update_turn_text(entity: Entity) -> void:
		turn_label.text = "Ход: " + entity.get_display_name()


func update_move_budget(current: int, max_budget: int) -> void:
		if move_budget_label != null:
				move_budget_label.text = "Движение: " + str(current) + "/" + str(max_budget)
				move_budget_label.visible = true


func hide_move_budget() -> void:
		if move_budget_label != null:
				move_budget_label.visible = false


# === СПОСОБНОСТИ ===

# Обновить UI способностей - показываем ВСЕ способности, disabled если недоступны
func update_abilities(hero: Hero) -> void:
		_clear_ability_buttons()
		
		var all_abilities: Array[Ability] = hero.get_all_abilities()
		
		# Отладка
		print("UI Update: AP=", hero.current_ap, ", MoveBudget=", hero.move_budget)
		
		for ability: Ability in all_abilities:
				var button: Button = Button.new()
				button.text = ability.ability_name + " (" + str(ability.ap_cost) + " AP)"
				button.tooltip_text = ability.description
				
				# Проверяем доступность способности
				var is_available: bool = ability.can_use(hero, hero.current_level)
				
				# Для способностей с целями проверяем наличие целей
				if is_available and ability.target_type != Ability.TargetType.NONE:
						is_available = ability.has_valid_targets(hero, hero.current_level)
				
				# Отладка
				print("  ", ability.ability_name, ": can_use=", ability.can_use(hero, hero.current_level), ", is_available=", is_available)
				
				button.disabled = not is_available
				
				if is_available:
						# Подключаем сигнал только для доступных кнопок
						button.pressed.connect(_on_ability_button_pressed.bind(ability.ability_name))
				else:
						# Для недоступных показываем причину в tooltip
						if hero.current_ap < ability.ap_cost:
								button.tooltip_text += "\n(Недостаточно AP)"
						elif ability.target_type == Ability.TargetType.TILE and ability.ability_name == "Перемещение":
								if hero.move_budget <= 0:
										button.tooltip_text += "\n(Нет запаса движения)"
								else:
										button.tooltip_text += "\n(Нет доступных клеток)"
						elif ability.target_type == Ability.TargetType.DIRECTION:
								button.tooltip_text += "\n(Нет целей рядом)"
				
				ability_container.add_child(button)
		
		# Обновляем запас движения
		update_move_budget(hero.move_budget, hero.max_move_budget)


func clear_abilities() -> void:
		_clear_ability_buttons()
		hide_move_budget()


func _clear_ability_buttons() -> void:
		for child: Node in ability_container.get_children():
				child.queue_free()


func _on_ability_button_pressed(ability_name: String) -> void:
		emit_signal("ability_selected", ability_name)


# === СООБЩЕНИЯ ===

func show_message(text: String) -> void:
		message_label.text = text
		message_label.visible = true
		
		var tween: Tween = create_tween()
		tween.tween_interval(2.0)
		tween.tween_callback(_hide_message)


func _hide_message() -> void:
		message_label.visible = false


# === ОБРАБОТЧИКИ КНОПОК ===

func _on_end_turn_pressed() -> void:
		emit_signal("end_turn_requested")


func _on_undo_local_pressed() -> void:
		emit_signal("undo_local_requested")


func _on_undo_round_start_pressed() -> void:
		emit_signal("undo_round_start_requested")


func _on_undo_full_round_pressed() -> void:
		emit_signal("undo_full_round_requested")
