class_name AbilityAction
extends Action

# Способность, которую используем
var ability: Ability = null

# Цель (позиция или сущность)
var target_pos: Vector2i = Vector2i.ZERO

# Внутреннее действие (MoveAction или AttackAction)
var inner_action: Action = null


func _init(actor: Entity, used_ability: Ability, target: Variant) -> void:
	super(actor)
	ability = used_ability
	
	if target is Vector2i:
		target_pos = target


# Выполнить способность
func execute(level: Level) -> bool:
	if ability == null:
		return false
	
	# Создаём действие через способность
	inner_action = ability.create_action(entity, target_pos, level)
	
	if inner_action == null:
		return false
	
	# Выполняем внутреннее действие
	return inner_action.execute(level)


# Отменить способность
func undo(level: Level) -> void:
	if inner_action != null:
		inner_action.undo(level)
