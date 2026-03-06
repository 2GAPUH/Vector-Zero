extends Camera2D
class_name CameraController

# === КОНСТАНТЫ ===
const MOVE_DURATION: float = 0.4
const FOLLOW_SMOOTHING: float = 10.0

# === ПАРАМЕТРЫ ===
# Зум камеры
@export var camera_zoom: Vector2 = Vector2(4, 4)

# Сущность для слежения
var target_entity: Entity = null

# === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_camera_start_pos: Vector2 = Vector2.ZERO
var _move_tween: Tween = null


func _ready() -> void:
	zoom = camera_zoom
	make_current()


func _process(delta: float) -> void:
	_handle_drag()
	_update_follow(delta)


# === СЛЕЖЕНИЕ ЗА СУЩНОСТЬЮ ===

func _update_follow(_delta: float) -> void:
	if target_entity == null:
		return
	
	if _is_dragging:
		return
	
	# Просто следуем за позицией сущности (плавно)
	# Это работает вместе с tween анимацией сущности
	global_position = target_entity.global_position


# Установить цель для слежения
func set_target(entity: Entity) -> void:
	target_entity = entity


# Остановить слежение
func clear_target() -> void:
	target_entity = null


# === ПЕРЕТАСКИВАНИЕ ===

func _handle_drag() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not _is_dragging:
		_start_drag()
	
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and _is_dragging:
		_end_drag()
	
	if _is_dragging:
		_update_drag()


func _start_drag() -> void:
	_is_dragging = true
	_drag_start_pos = get_global_mouse_position()
	_drag_camera_start_pos = global_position
	
	# Отменяем текущую анимацию
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()


func _end_drag() -> void:
	_is_dragging = false


func _update_drag() -> void:
	var current_mouse_pos: Vector2 = get_global_mouse_position()
	var delta: Vector2 = _drag_start_pos - current_mouse_pos
	global_position = _drag_camera_start_pos + delta


# === ПРОВЕРКА ВИДИМОСТИ ===

func is_entity_visible(entity: Entity) -> bool:
	var entity_pos: Vector2 = entity.global_position
	var camera_pos: Vector2 = global_position
	
	var viewport_size: Vector2 = get_viewport_rect().size
	var visible_size: Vector2 = viewport_size / zoom
	
	var half_visible: Vector2 = visible_size / 2
	var left: float = camera_pos.x - half_visible.x
	var right: float = camera_pos.x + half_visible.x
	var top: float = camera_pos.y - half_visible.y
	var bottom: float = camera_pos.y + half_visible.y
	
	return entity_pos.x >= left and entity_pos.x <= right and entity_pos.y >= top and entity_pos.y <= bottom


# === ПЕРЕМЕЩЕНИЕ КАМЕРЫ ===

func move_to_entity(entity: Entity) -> void:
	if is_entity_visible(entity):
		return
	
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	
	_move_tween = create_tween()
	_move_tween.tween_property(self, "global_position", entity.global_position, MOVE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func move_to_entity_async(entity: Entity) -> void:
	if is_entity_visible(entity):
		return
	
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	
	_move_tween = create_tween()
	_move_tween.tween_property(self, "global_position", entity.global_position, MOVE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await _move_tween.finished


func teleport_to(pos: Vector2) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	global_position = pos


func teleport_to_entity(entity: Entity) -> void:
	teleport_to(entity.global_position)
	target_entity = entity
