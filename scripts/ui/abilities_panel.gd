class_name AbilitiesPanel
extends Control

# === ПАНЕЛЬ СПОСОБНОСТЕЙ ===

# Сигналы
signal ability_selected(ability: Ability)
signal end_turn_requested

# Контейнер для кнопок способностей
@onready var abilities_container: HBoxContainer = $MarginContainer/VBoxContainer/AbilitiesContainer

# Лейблы статистики
@onready var hp_label: Label = $MarginContainer/VBoxContainer/StatsContainer/HpLabel
@onready var ap_label: Label = $MarginContainer/VBoxContainer/StatsContainer/ApLabel
@onready var move_label: Label = $MarginContainer/VBoxContainer/StatsContainer/MoveLabel

# Кнопка завершения хода
@onready var end_turn_button: Button = $MarginContainer/VBoxContainer/EndTurnButton

# Текущая сущность
var _entity: Entity = null

# Кнопки способностей
var _ability_buttons: Array[Button] = []

# Текущая выбранная способность
var _selected_ability: Ability = null


func _ready() -> void:
	# Подключаем кнопку завершения хода
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)


# === НАСТРОЙКА ПАНЕЛИ ===
func setup(entity: Entity) -> void:
	_entity = entity
	_clear_ability_buttons()
	_create_ability_buttons()
	_update_stats()
	_connect_entity_signals()


# === ОЧИСТКА КНОПОК ===
func _clear_ability_buttons() -> void:
	for button: Button in _ability_buttons:
		if is_instance_valid(button):
			button.queue_free()
	_ability_buttons.clear()


# === СОЗДАНИЕ КНОПОК СПОСОБНОСТЕЙ ===
func _create_ability_buttons() -> void:
	if _entity == null:
		return
	
	if abilities_container == null:
		return
	
	for ability: Ability in _entity.abilities:
		var button: Button = Button.new()
		button.text = ability.name
		button.tooltip_text = ability.description + "\nСтоимость: " + str(ability.cost) + " AP"
		button.custom_minimum_size = Vector2(100, 40)
		
		# Подключаем сигнал нажатия
		button.pressed.connect(_on_ability_button_pressed.bind(ability))
		
		abilities_container.add_child(button)
		_ability_buttons.append(button)


# === ОБНОВЛЕНИЕ СТАТИСТИКИ ===
func _update_stats() -> void:
	if _entity == null:
		return
	
	if hp_label:
		hp_label.text = "HP: " + str(_entity.current_hp) + "/" + str(_entity.max_hp)
	
	if ap_label:
		ap_label.text = "AP: " + str(_entity.current_ap) + "/" + str(_entity.max_ap)
	
	if move_label:
		move_label.text = "Перемещение: " + str(_entity.move_pool)


# === ПОДКЛЮЧЕНИЕ СИГНАЛОВ СУЩНОСТИ ===
func _connect_entity_signals() -> void:
	if _entity == null:
		return
	
	if not _entity.is_connected("hp_changed", _on_entity_hp_changed):
		_entity.hp_changed.connect(_on_entity_hp_changed)
	
	if not _entity.is_connected("ap_changed", _on_entity_ap_changed):
		_entity.ap_changed.connect(_on_entity_ap_changed)
	
	if not _entity.is_connected("move_pool_changed", _on_entity_move_pool_changed):
		_entity.move_pool_changed.connect(_on_entity_move_pool_changed)


# === ОБНОВЛЕНИЕ СОСТОЯНИЯ КНОПОК ===
func update_buttons_state() -> void:
	for i: int in range(_ability_buttons.size()):
		if i < _entity.abilities.size():
			var ability: Ability = _entity.abilities[i]
			var button: Button = _ability_buttons[i]
			
			button.disabled = not ability.can_use()
			
			# Подсвечиваем выбранную способность
			if ability == _selected_ability:
				button.modulate = Color(1.2, 1.2, 0.8)
			else:
				button.modulate = Color.WHITE


# === УСТАНОВИТЬ ВЫБРАННУЮ СПОСОБНОСТЬ ===
func set_selected_ability(ability: Ability) -> void:
	_selected_ability = ability
	update_buttons_state()


# === ОЧИСТИТЬ ВЫБОР ===
func clear_selection() -> void:
	_selected_ability = null
	update_buttons_state()


# === ОБРАБОТЧИКИ СИГНАЛОВ ===

func _on_ability_button_pressed(ability: Ability) -> void:
	_selected_ability = ability
	emit_signal("ability_selected", ability)
	update_buttons_state()


func _on_end_turn_pressed() -> void:
	emit_signal("end_turn_requested")


func _on_entity_hp_changed(current: int, maximum: int) -> void:
	if hp_label:
		hp_label.text = "HP: " + str(current) + "/" + str(maximum)


func _on_entity_ap_changed(current: int, maximum: int) -> void:
	if ap_label:
		ap_label.text = "AP: " + str(current) + "/" + str(maximum)
	update_buttons_state()


func _on_entity_move_pool_changed(current: int) -> void:
	if move_label:
		move_label.text = "Перемещение: " + str(current)
	update_buttons_state()
