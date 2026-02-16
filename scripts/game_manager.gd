extends Node

var _current_level: Node2D = null
var tile_size: Vector2i = Vector2i.ZERO

func set_level(level: Node) -> void:
	_current_level = level
	tile_size = level.get_tile_size()
