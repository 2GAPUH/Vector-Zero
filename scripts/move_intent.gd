class_name MoveIntent
extends Intent

var direction: Vector2i

func _init(actor: Entity, dir: Vector2i) -> void:
	super(actor)
	direction = dir

func get_preview_position() -> Vector2i:
	return entity.tile_position + direction

func get_type_name() -> String:
	return "move"
