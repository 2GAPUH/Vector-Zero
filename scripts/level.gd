extends Node2D
class_name Level
@onready var tile_map: TileMapLayer = $Walls
# {Vector2i: Entity}
var _occupied = {}

func _ready() -> void:
	GameManager.set_level(self)

func get_tile_size() -> Vector2i:
	return tile_map.tile_set.tile_size

func is_tile_passable(tile_pos: Vector2i) -> bool:
	return tile_map.get_cell_source_id(tile_pos) == -1

func tile_to_local(tile_pos: Vector2i) -> Vector2:
	return tile_map.map_to_local(tile_pos)

func local_to_tile(world_pos: Vector2) -> Vector2i:
	return tile_map.local_to_map(world_pos)

func register_entity(entity: Entity, tile_pos: Vector2i):
	if is_cell_free(tile_pos) and is_tile_passable(tile_pos):
		_occupied[tile_pos] = entity
		if not entity.is_connected("request_action", Callable(self, "_on_entity_request_action")):
			entity.connect("request_action", Callable(self, "_on_entity_request_action"))
		print("Setup entity")
		entity.setup(self)

func update_entity_position(old_pos: Vector2i, new_pos: Vector2i, entity: Entity) -> void:
	_occupied.erase(old_pos)
	_occupied[new_pos] = entity

func _on_entity_request_action(action: Action) -> void:
	var success = action.execute(self)
	
	if success:
		action.entity.history.append(action)

func _on_entity_request_move(entity: Entity, direction: Vector2i) -> void:
	var start_pos = entity.tile_position
	var target_pos = start_pos + direction
	
	if is_cell_free(target_pos):
		if is_tile_passable(target_pos):
			_occupied.erase(start_pos)
			_occupied[target_pos] = entity
			
			entity.move_success(direction)
		else:
			print("Cell is unpassable")
			entity.move_fail()
	else:
		print("Cell is _occupied")
		entity.move_fail()

func is_cell_free(tile_pos) -> bool:
	return not _occupied.has(tile_pos)

func get_player_position() -> Vector2i:
	
	for pos in _occupied:
		if _occupied[pos] is Player:
			return pos
	return Vector2i.ZERO
