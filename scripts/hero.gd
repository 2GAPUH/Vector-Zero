extends Entity
class_name Hero

# === КОНСТАНТЫ ===
const MOVE_RANGE: int = 2
const DASH_RANGE: int = 6
const ATTACK_RANGE: int = 1

# === ПЕРЕМЕННЫЕ ===
# Выбранная способность для использования
var _selected_ability: Ability = null


func _ready() -> void:
		super._ready()
		_initialize_abilities()


# Инициализация способностей героя
func _initialize_abilities() -> void:
		# Базовое перемещение (бесплатное)
		var move_ability: MoveAbility = MoveAbility.new()
		move_ability.ability_name = "Перемещение"
		move_ability.ap_cost = 0
		move_ability.range = MOVE_RANGE
		add_ability(move_ability)
		
		# Рывок (стоит 1 AP)
		var dash_ability: DashAbility = DashAbility.new()
		dash_ability.ability_name = "Рывок"
		dash_ability.ap_cost = 1
		dash_ability.range = DASH_RANGE
		add_ability(dash_ability)
		
		# Атака (стоит 1 AP)
		var attack_ability: AttackAbility = AttackAbility.new()
		attack_ability.ability_name = "Атака"
		attack_ability.ap_cost = 1
		attack_ability.range = ATTACK_RANGE
		attack_ability.damage = base_damage
		add_ability(attack_ability)


# Начать ход героя
func _start_turn() -> void:
		super._start_turn()
		_selected_ability = null
		print("Ход героя начался. AP: ", current_ap)


# Обработка ввода
func _unhandled_input(event: InputEvent) -> void:
		if not is_my_turn:
				return
		
		# Обработка клавиатуры
		if event is InputEventKey:
				if event.is_pressed() and not event.is_echo():
						_handle_keyboard_input(event)
				return
		
		# Обработка клика мыши
		if event is InputEventMouseButton:
				if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
						_handle_left_click(event)
				elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
						_handle_right_click(event)


# Обработка клавиатуры
func _handle_keyboard_input(event: InputEventKey) -> void:
		# Space - завершить ход
		if event.keycode == KEY_SPACE:
				end_turn()
				get_viewport().set_input_as_handled()


# Обработка левого клика
func _handle_left_click(event: InputEventMouseButton) -> void:
		# Получаем позицию клика в мировых координатах
		var global_click_pos: Vector2 = get_global_mouse_position()
		var click_pos: Vector2i = current_level.local_to_tile(global_click_pos)
		
		print("Клик по клетке: ", click_pos, " глобальная позиция: ", global_click_pos)
		
		# Если выбрана способность - пытаемся использовать
		if _selected_ability != null:
				_try_use_ability(_selected_ability, click_pos)
		else:
				# Если способность не выбрана, пытаемся переместиться по умолчанию
				var move_ability: Ability = get_ability_by_name("Перемещение")
				if move_ability != null and move_ability.can_use(self, current_level):
						_try_use_ability(move_ability, click_pos)


# Обработка правого клика (отмена выбора способности)
func _handle_right_click(_event: InputEventMouseButton) -> void:
		_selected_ability = null


# Выбрать способность для использования
func select_ability(ability_name: String) -> bool:
		var ability: Ability = get_ability_by_name(ability_name)
		if ability == null:
				return false
		
		if not ability.can_use(self, current_level):
				return false
		
		_selected_ability = ability
		return true


# Попытаться использовать способность
func _try_use_ability(ability: Ability, target_pos: Vector2i) -> void:
		# Проверяем, что цель валидна
		var valid_targets: Array[Vector2i] = ability.get_valid_targets(self, current_level)
		
		if not valid_targets.has(target_pos):
				print("Невалидная цель")
				return
		
		# Создаём действие через способность
		var action: Action = ability.create_action(self, target_pos, current_level)
		
		if action == null:
				print("Не удалось создать действие")
				return
		
		# Отправляем действие на выполнение
		emit_signal("request_action", action)
		
		# Сбрасываем выбранную способность
		_selected_ability = null


# Получить валидные цели для текущей выбранной способности
func get_valid_targets_for_selected() -> Array[Vector2i]:
		if _selected_ability == null:
				return []
		return _selected_ability.get_valid_targets(self, current_level)


# Получить все способности, которые можно использовать сейчас
func get_available_abilities() -> Array[Ability]:
		var result: Array[Ability] = []
		for ability: Ability in abilities:
				if ability.can_use(self, current_level):
						result.append(ability)
		return result


# === ИНФОРМАЦИЯ ===

func get_display_name() -> String:
		return "Герой"
