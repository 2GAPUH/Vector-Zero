extends Area2D
class_name Entity

signal turn_finished
signal request_action(action: Action)

var tile_position: Vector2i = Vector2i.ZERO
var movement_vect: Vector2i = Vector2i.ZERO
@export var speed: int = 1;
var current_level: Level

var history: Array[Action] = []

func move():
		position += Vector2(GameManager.tile_size * movement_vect)
		tile_position += movement_vect

func _start_turn():
		# базовая реализация, переопределяется в наследниках
		emit_signal("turn_finished")

func setup(level: Level):
		current_level = level
		tile_position = level.local_to_tile(position)

func move_success(direction: Vector2i):
		print("Move success")
		tile_position += direction
		
		var tween: Tween = create_tween()
		tween.tween_property(self, "global_position", current_level.tile_to_local(tile_position), 0.3).set_trans(Tween.TRANS_SINE)
		
		emit_signal("turn_finished")

func move_fail():
		print("Move failed")
		emit_signal("turn_finished")

func get_intent() -> Intent:
		return null
