extends Entity
class_name Hero

# === ГЕРОЙ (ИГРОК) ===

# Флаг: сейчас ход героя
var _is_my_turn: bool = false

# Выбранная способность
var _selected_ability: Ability = null

# Сигнал о выборе способности
signal ability_selected(ability: Ability)


func _ready() -> void:
	super._ready()
	
	# Добавляем способности герою
	add_ability(MoveAbility.new())
	add_ability(DashAbility.new())
	add_ability(AttackAbility.new())


# === НАЧАТЬ ХОД ГЕРОЯ ===
func _start_turn() -> void:
	super._start_turn()
	_is_my_turn = true
	_selected_ability = null


# === ОБРАБОТКА ВВОДА ===
func _unhandled_input(event: InputEvent) -> void:
	if not _is_my_turn:
		return
	
	# Завершение хода по Space
	if event is InputEventKey:
		if event.is_action_pressed("ui_accept") or event.keycode == KEY_SPACE:
			if not event.is_echo() and event.is_pressed():
				end_turn()
				get_viewport().set_input_as_handled()
				return
	
	# Обработка мыши
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_left_click(event.position)
			get_viewport().set_input_as_handled()


# === ОБРАБОТКА ЛЕВОГО КЛИКА ===
func _handle_left_click(screen_pos: Vector2) -> void:
	var tile_pos: Vector2i = current_level.local_to_tile(screen_pos)
	
	# Если есть выбранная способность — пытаемся использовать
	if _selected_ability != null:
		if _selected_ability.is_valid_target(tile_pos):
			_execute_ability(_selected_ability, tile_pos)
		else:
			# Клик по недопустимой цели — сбрасываем выбор
			_clear_selection()
	else:
		# По умолчанию — пытаемся переместиться
		_try_move(tile_pos)


# === ВЫБОР СПОСОБНОСТИ ===
func select_ability(ability: Ability) -> void:
	if not _is_my_turn:
		return
	
	if not ability.can_use():
		return
	
	_selected_ability = ability
	emit_signal("ability_selected", ability)
	
	# Подсвечиваем доступные цели
	_highlight_ability_targets(ability)


# === ОЧИСТИТЬ ВЫБОР ===
func _clear_selection() -> void:
	_selected_ability = null
	current_level.clear_highlight()


# === ВЫПОЛНИТЬ СПОСОБНОСТЬ ===
func _execute_ability(ability: Ability, target: Variant) -> void:
	if ability.execute(target):
		# После выполнения обновляем подсветку
		_update_highlight()
	else:
		_clear_selection()


# === ПОПЫТКА ПЕРЕМЕЩЕНИЯ ===
func _try_move(tile_pos: Vector2i) -> void:
	var move_ability: Ability = _get_move_ability()
	if move_ability == null:
		return
	
	if move_ability.can_use() and move_ability.is_valid_target(tile_pos):
		move_ability.execute(tile_pos)


# === ПОЛУЧИТЬ СПОСОБНОСТЬ ПЕРЕМЕЩЕНИЯ ===
func _get_move_ability() -> Ability:
	for ability: Ability in abilities:
		if ability is MoveAbility:
			return ability
	return null


# === ПОДСВЕТКА ЦЕЛЕЙ СПОСОБНОСТИ ===
func _highlight_ability_targets(ability: Ability) -> void:
	var targets: Array[Vector2i] = ability.get_valid_targets()
	current_level.highlight_tiles(targets, ability.get_highlight_color())


# === ОБНОВИТЬ ПОДСВЕТКУ ===
func _update_highlight() -> void:
	if _selected_ability != null and _selected_ability.can_use():
		_highlight_ability_targets(_selected_ability)
	else:
		_clear_selection()


# === ЗАВЕРШИТЬ ХОД ===
func end_turn() -> void:
	_is_my_turn = false
	_clear_selection()
	super.end_turn()


# === ПРОВЕРИТЬ, СЕЙЧАС ЛИ ХОД ЭТОГО ГЕРОЯ ===
func is_my_turn() -> bool:
	return _is_my_turn


# === ПОЛУЧИТЬ ВЫБРАННУЮ СПОСОБНОСТЬ ===
func get_selected_ability() -> Ability:
	return _selected_ability


# === ХОТКЕИ ДЛЯ СПОСОБНОСТЕЙ ===
func _input(event: InputEvent) -> void:
	if not _is_my_turn:
		return
	
	if event is InputEventKey and event.pressed and not event.is_echo():
		match event.keycode:
			KEY_1:
				_select_ability_by_index(0)
			KEY_2:
				_select_ability_by_index(1)
			KEY_3:
				_select_ability_by_index(2)
			KEY_ESCAPE:
				_clear_selection()


# === ВЫБОР СПОСОБНОСТИ ПО ИНДЕКСУ ===
func _select_ability_by_index(index: int) -> void:
	if index >= 0 and index < abilities.size():
		select_ability(abilities[index])
