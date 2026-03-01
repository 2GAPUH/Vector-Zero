extends Control

# Сигналы
signal end_turn_requested
signal undo_local_requested
signal undo_round_start_requested
signal undo_full_round_requested

# Ссылки на элементы UI
@onready var round_label: Label = $VBoxContainer/InfoContainer/RoundLabel
@onready var turn_label: Label = $VBoxContainer/InfoContainer/TurnLabel
@onready var turn_order_container: HBoxContainer = $VBoxContainer/TurnOrderContainer
@onready var message_label: Label = $VBoxContainer/MessageContainer/MessageLabel

# Порядок ходов
var _turn_order: Array[Entity] = []
var _current_turn_index: int = 0


func _ready() -> void:
	# Подключаем кнопки
	$VBoxContainer/ButtonContainer/EndTurnButton.pressed.connect(_on_end_turn_pressed)
	$VBoxContainer/ButtonContainer/UndoLocalButton.pressed.connect(_on_undo_local_pressed)
	$VBoxContainer/ButtonContainer/UndoRoundStartButton.pressed.connect(_on_undo_round_start_pressed)
	$VBoxContainer/ButtonContainer/UndoFullRoundButton.pressed.connect(_on_undo_full_round_pressed)


# Установить порядок ходов
func set_turn_order(entities: Array[Entity]) -> void:
	_turn_order = entities
	_rebuild_turn_order_ui()


# Перестроить UI очередности ходов
func _rebuild_turn_order_ui() -> void:
	# Удаляем старые элементы
	for child: Node in turn_order_container.get_children():
		child.queue_free()
	
	# Создаём новые элементы для каждой сущности
	for i: int in range(_turn_order.size()):
		var entity: Entity = _turn_order[i]
		var label: Label = Label.new()
		
		# Формируем текст
		if entity is Hero:
			label.text = "Герой"
		else:
			label.text = "Враг"
		
		# Выделяем текущий ход
		if i == _current_turn_index:
			label.modulate = Color.YELLOW
		else:
			label.modulate = Color.WHITE
		
		turn_order_container.add_child(label)


# Установить текущий индекс хода
func set_current_turn(index: int) -> void:
	_current_turn_index = index
	_rebuild_turn_order_ui()


# Обновить текст раунда
func update_round_text(round_number: int) -> void:
	round_label.text = "Раунд: " + str(round_number)


# Обновить текст хода
func update_turn_text(entity: Entity) -> void:
	if entity is Hero:
		turn_label.text = "Ход: Герой"
	else:
		turn_label.text = "Ход: Враг (" + entity.name + ")"


# Показать сообщение
func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	
	# Скрываем через 2 секунды
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
