extends Node2D

@onready var level: Level = $Level
@onready var turn_queue: TurnQueue = $TurnQueue 
@onready var player: Player = $Player
@onready var enemies: Array = [$Enemy1, $Enemy2] 
@onready var game_ui: Control = $CanvasLayer/GameUI
@onready var intent_manager: IntentManager = $IntentManager

func _ready() -> void:
	level.register_entity(player, level.local_to_tile(player.position))
	
	for e: Enemy in enemies:
		level.register_entity(e, level.local_to_tile(e.position))
	
	var all_entities: Array = []
	all_entities.append(player)
	all_entities.append_array(enemies)
	
	turn_queue.connect("turn_started", _on_turn_started)
	
	intent_manager.setup(level)
	intent_manager.refresh_intents(all_entities)
	
	turn_queue.initialize(all_entities)
	turn_queue.start_queue()

func _on_turn_started(entity: Entity) -> void:
	_update_ui(entity)
	_refresh_intents_after_turn(entity)

func _update_ui(entity: Entity) -> void:
	if entity is Player:
		game_ui.update_turn_text("Игрок")
	else:
		game_ui.update_turn_text("Враг")

func _refresh_intents_after_turn(entity: Entity) -> void:
	if entity is Player:
		var all_entities: Array = []
		all_entities.append(player)
		all_entities.append_array(enemies)
		intent_manager.refresh_intents(all_entities)
