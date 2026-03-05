class_name MoveAction
extends Action

var direction: Vector2i
var start_pos: Vector2i
var target_pos: Vector2i

func _init(actor: Entity, dir: Vector2i) -> void:
	super(actor)
	direction = dir

func execute(level: Level) -> bool:
	start_pos = entity.tile_position
	target_pos = start_pos + direction
	
	if level.is_cell_free(target_pos) and level.is_tile_passable(target_pos):
		level.update_entity_position(start_pos, target_pos, entity)
		entity.move_success(direction)
		return true
	else:
		print("Cell is unpassable or occupied")
		entity.move_fail()
		return false

func undo(level: Level) -> void:
	level.update_entity_position(target_pos, start_pos, entity)
	entity.move_success(-direction)
