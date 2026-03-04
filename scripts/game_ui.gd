extends Control
class_name GameUI

# === ИГРОВОЙ UI ===

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

# Панель способностей
@onready var abilities_panel: AbilitiesPanel = $AbilitiesPanel

# Порядок ходов
var _turn_order: Array[Entity] = []
var _current_turn_index: int = 0


func _ready() -> void:
		# Подключаем кнопки
		var end_turn_btn: Button = $VBoxContainer/ButtonContainer/EndTurnButton
		if end_turn_btn:
				end_turn_btn.pressed.connect(_on_end_turn_pressed)
		
		var undo_local_btn: Button = $VBoxContainer/ButtonContainer/UndoLocalButton
		if undo_local_btn:
				undo_local_btn.pressed.connect(_on_undo_local_pressed)
		
		var undo_round_btn: Button = $VBoxContainer/ButtonContainer/UndoRoundStartButton
		if undo_round_btn:
				undo_round_btn.pressed.connect(_on_undo_round_start_pressed)
		
		var undo_full_btn: Button = $VBoxContainer/ButtonContainer/UndoFullRoundButton
		if undo_full_btn:
				undo_full_btn.pressed.connect(_on_undo_full_round_pressed)


# === УСТАНОВИТЬ ПОРЯДОК ХОДОВ ===
func set_turn_order(entities: Array[Entity]) -> void:
		_turn_order = entities
		_rebuild_turn_order_ui()


# === ПЕРЕСТРОИТЬ UI ОЧЕРЕДНОСТИ ===
func _rebuild_turn_order_ui() -> void:
		if turn_order_container == null:
				return
		
		# Удаляем старые элементы
		for child: Node in turn_order_container.get_children():
				child.queue_free()
		
		# Создаём новые элементы
		for i: int in range(_turn_order.size()):
				var entity: Entity = _turn_order[i]
				var label: Label = Label.new()
				
				# Формируем текст
				if entity is Hero:
						label.text = "Герой"
				elif entity is Enemy:
						label.text = "Враг"
				else:
						label.text = entity.name
				
				# Выделяем текущий ход
				if i == _current_turn_index:
						label.modulate = Color.YELLOW
				elif not entity.is_alive:
						label.modulate = Color.GRAY
				else:
						label.modulate = Color.WHITE
				
				turn_order_container.add_child(label)


# === УСТАНОВИТЬ ТЕКУЩИЙ ИНДЕКС ===
func set_current_turn(index: int) -> void:
		_current_turn_index = index
		_rebuild_turn_order_ui()


# === ОБНОВИТЬ ТЕКСТ РАУНДА ===
func update_round_text(round_number: int) -> void:
		if round_label:
				round_label.text = "Раунд: " + str(round_number)


# === ОБНОВИТЬ ТЕКСТ ХОДА ===
func update_turn_text(entity: Entity) -> void:
		if turn_label == null:
				return
		
		if entity is Hero:
				turn_label.text = "Ход: Герой"
		elif entity is Enemy:
				turn_label.text = "Ход: Враг"
		else:
				turn_label.text = "Ход: " + entity.name


# === ПОКАЗАТЬ СООБЩЕНИЕ ===
func show_message(text: String) -> void:
		if message_label == null:
				return
		
		message_label.text = text
		message_label.visible = true
		
		var tween: Tween = create_tween()
		tween.tween_interval(2.0)
		tween.tween_callback(_hide_message)


func _hide_message() -> void:
		if message_label:
				message_label.visible = false


# === НАСТРОИТЬ ПАНЕЛЬ СПОСОБНОСТЕЙ ===
func setup_abilities_panel(entity: Entity) -> void:
		if abilities_panel:
				abilities_panel.setup(entity)


# === ОБРАБОТЧИКИ КНОПОК ===

func _on_end_turn_pressed() -> void:
		emit_signal("end_turn_requested")


func _on_undo_local_pressed() -> void:
		emit_signal("undo_local_requested")


func _on_undo_round_start_pressed() -> void:
		emit_signal("undo_round_start_requested")


func _on_undo_full_round_pressed() -> void:
		emit_signal("undo_full_round_requested")
