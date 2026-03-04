class_name AttackAction
extends Action

# === ДЕЙСТВИЕ: АТАКА ===

# Позиция цели
var target_position: Vector2i

# Цель атаки
var target_entity: Entity

# Нанесённый урон
var damage_amount: int

# HP цели до атаки (для отката)
var target_hp_before: int


func _init(actor: Entity, target: Entity, damage: int, pos: Vector2i) -> void:
	super(actor)
	target_entity = target
	damage_amount = damage
	target_position = pos
	
	# Запоминаем HP до атаки
	if target_entity != null:
		target_hp_before = target_entity.current_hp


# === ВЫПОЛНЕНИЕ АТАКИ ===
func execute(level: Level) -> bool:
	# Атака уже выполнена через Ability.execute()
	# Здесь только логика записи в историю
	return true


# === ОТКАТ АТАКИ ===
func undo(level: Level) -> void:
	if target_entity == null:
		return
	
	if not is_instance_valid(target_entity):
		return
	
	# Восстанавливаем HP цели
	target_entity.current_hp = target_hp_before
	
	# Если цель была мертва — воскрешаем
	if target_entity.current_hp > 0:
		target_entity.is_alive = true
	
	target_entity.emit_signal("hp_changed", target_entity.current_hp, target_entity.max_hp)
