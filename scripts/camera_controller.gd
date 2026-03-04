extends Camera2D
class_name CameraController

# === КАМЕРА ===

# Скорость перемещения камеры к сущности (длительность в секундах)
const MOVE_DURATION: float = 0.3

# Зум камеры
@export var camera_zoom: Vector2 = Vector2(4, 4)

# Состояние перетаскивания
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_camera_start_pos: Vector2 = Vector2.ZERO

# Текущая анимация перемещения
var _move_tween: Tween = null

# Флаг: камера в движении
var _is_moving: bool = false


func _ready() -> void:
	zoom = camera_zoom
	make_current()


func _process(_delta: float) -> void:
	_handle_drag()


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
	_kill_tween()


func _end_drag() -> void:
	_is_dragging = false


func _update_drag() -> void:
	var current_mouse_pos: Vector2 = get_global_mouse_position()
	var delta: Vector2 = _drag_start_pos - current_mouse_pos
	global_position = _drag_camera_start_pos + delta


func is_entity_visible(entity: Entity) -> bool:
	var entity_pos: Vector2 = entity.global_position
	var camera_pos: Vector2 = global_position
	
	var viewport_size: Vector2 = get_viewport_rect().size
	var visible_size: Vector2 = viewport_size / zoom
	
	var margin: float = 20.0
	var half_visible: Vector2 = (visible_size / 2) - Vector2(margin, margin)
	
	var left: float = camera_pos.x - half_visible.x
	var right: float = camera_pos.x + half_visible.x
	var top: float = camera_pos.y - half_visible.y
	var bottom: float = camera_pos.y + half_visible.y
	
	return entity_pos.x >= left and entity_pos.x <= right and entity_pos.y >= top and entity_pos.y <= bottom


func move_to_entity(entity: Entity) -> void:
	if is_entity_visible(entity) and not _is_moving:
		return
	
	_kill_tween()
	_is_moving = true
	
	_move_tween = create_tween()
	_move_tween.tween_property(self, "global_position", entity.global_position, MOVE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_move_tween.finished.connect(_on_move_finished)


func move_to_entity_async(entity: Entity) -> void:
	if is_entity_visible(entity):
		return
	
	_kill_tween()
	_is_moving = true
	
	_move_tween = create_tween()
	_move_tween.tween_property(self, "global_position", entity.global_position, MOVE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_move_tween.finished.connect(_on_move_finished)
	
	await _move_tween.finished


func _on_move_finished() -> void:
	_is_moving = false


func teleport_to(pos: Vector2) -> void:
	_kill_tween()
	global_position = pos
	_is_moving = false


func teleport_to_entity(entity: Entity) -> void:
	teleport_to(entity.global_position)


func center_on_entity(entity: Entity) -> void:
	teleport_to_entity(entity)


func _kill_tween() -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = null
