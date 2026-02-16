class_name Action
extends RefCounted

var entity: Entity

func _init(actor: Entity) -> void:
	entity = actor

func execute(level: Level) -> bool:
	return false

func undo(level: Level) -> void:
	pass
