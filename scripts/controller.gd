class_name Controller
extends RefCounted

var entity: Entity

func _init(actor: Entity) -> void:
	entity = actor

func get_intent() -> Intent:
	return null

func get_action() -> Action:
	return null
