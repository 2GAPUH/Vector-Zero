extends Entity
class_name Enemy

var planned_action: Action
@onready var intent_sprite: Sprite2D = $IntentSprite

func setup(level: Level) -> void:
	super.setup(level)
	_plan_action()

func _plan_action() -> void:
	if not current_level:
		print("Level not initialized")
		return
	
	var target_pos: Vector2i = current_level.get_player_position()
	var direction: Vector2i = target_pos - tile_position
	var move_dir: Vector2i = Vector2i.ZERO
	
	if direction.x != 0:
		move_dir.x = sign(direction.x)
	elif direction.y != 0:
		move_dir.y = sign(direction.y)
	
	if move_dir != Vector2i.ZERO:
		planned_action = MoveAction.new(self, move_dir)
		_show_intent(move_dir)
	else:
		planned_action = null
		if intent_sprite:
			intent_sprite.hide()

func _show_intent(dir: Vector2i) -> void:
	if intent_sprite:
		intent_sprite.show()
		var target_tile = tile_position + dir
		intent_sprite.global_position = current_level.tile_to_local(target_tile)

func _start_turn() -> void:
	if intent_sprite:
		intent_sprite.hide()
	
	if planned_action:
		print("Executing planned action")
		emit_signal("request_action", planned_action)
		planned_action = null
	else:
		print("Zero movement planned")
		emit_signal("turn_finished")

func move_success(direction: Vector2i) -> void:
	super.move_success(direction)
	_plan_action()

func move_fail() -> void:
	super.move_fail()
	_plan_action()
