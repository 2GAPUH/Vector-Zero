class_name Intent
extends RefCounted

var entity: Entity

func _init(actor: Entity) -> void:
	entity = actor

func get_preview_position() -> Vector2i:
	return entity.tile_position

func get_type_name() -> String:
	return "unknown"
