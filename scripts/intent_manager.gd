class_name IntentManager
extends Node2D

const ICON_TEXTURE: Texture2D = preload("res://resources/caution .png")

var _level: Level
var _intent_icons: Dictionary = {}

func setup(level: Level) -> void:
	_level = level

func refresh_intents(entities: Array) -> void:
	clear_all()
	
	for entity: Entity in entities:
		var intent: Intent = entity.get_intent()
		if intent != null:
			_create_intent_icon(intent)

func clear_all() -> void:
	for entity: Entity in _intent_icons.keys():
		var sprite: Sprite2D = _intent_icons[entity]
		sprite.queue_free()
	_intent_icons.clear()

func _create_intent_icon(intent: Intent) -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = ICON_TEXTURE
	sprite.position = _level.tile_to_local(intent.get_preview_position())
	sprite.modulate = Color(1, 1, 1, 0.7)
	sprite.scale = Vector2(0.5, 0.5)
	
	add_child(sprite)
	_intent_icons[intent.entity] = sprite
