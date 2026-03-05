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


# === СПОСОБНОСТИ ===

func update_abilities(abilities: Array[Ability]) -> void:
	_clear_ability_buttons()
	
	for ability: Ability in abilities:
		var button: Button = Button.new()
		button.text = ability.ability_name + " (" + str(ability.ap_cost) + " AP)"
		button.tooltip_text = ability.description
		
		# Подключаем сигнал
		button.pressed.connect(_on_ability_button_pressed.bind(ability.ability_name))
		
		ability_container.add_child(button)


func clear_abilities() -> void:
	_clear_ability_buttons()


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
