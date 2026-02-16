extends Node2D

@onready var level: Level = $Level
@onready var turn_queue: TurnQueue = $TurnQueue 
@onready var player: Player = $Player
@onready var enemies: Array = [$Enemy1, $Enemy2] 
@onready var game_ui = $CanvasLayer/GameUI

func _ready() -> void:
	level.register_entity(player, level.local_to_tile(player.position))
	
	for e: Enemy in enemies:
		level.register_entity(e, level.local_to_tile(e.position))
	
	var all_entities: Array = []
	all_entities.append(player)
	all_entities.append_array(enemies)
	
	turn_queue.connect("turn_started", _on_turn_started_ui_update)
	
	turn_queue.initialize(all_entities)
	turn_queue.start_queue()

func _on_turn_started_ui_update(entity: Entity) -> void:
	if entity is Player:
		game_ui.update_turn_text("Игрок")
	else:
		game_ui.update_turn_text("Враг")
