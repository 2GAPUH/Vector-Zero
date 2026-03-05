class_name AttackAction
extends Action

# Цель атаки
var target: Entity = null

# Урон
var damage: int = 1

# Позиция цели до атаки (для undo)
var target_tile_pos: Vector2i = Vector2i.ZERO

# HP цели до атаки (для undo)
var target_hp_before: int = 0


func _init(actor: Entity, target_entity: Entity, dmg: int) -> void:
	super(actor)
	target = target_entity
	damage = dmg
	target_tile_pos = target_entity.tile_position
	target_hp_before = target_entity.hp


# Выполнить атаку
func execute(level: Level) -> bool:
	if target == null or not target.is_alive:
		return false
	
	# Проверяем дистанцию
	var distance: int = abs(entity.tile_position.x - target.tile_position.x) + abs(entity.tile_position.y - target.tile_position.y)
	if distance != 1:
		return false
	
	# Наносим урон
	target.take_damage(damage)
	
	print(entity.get_display_name(), " атакует ", target.get_display_name(), " на ", damage, " урона")
	
	# Если цель умерла
	if not target.is_alive:
		_handle_target_death(level)
	
	return true


# Обработать смерть цели
func _handle_target_death(level: Level) -> void:
	print(target.get_display_name(), " погибает!")
	
	# Создаём труп
	var corpse: Obstacle = Obstacle.create_corpse(target)
	
	# Удаляем сущность с уровня
	level.unregister_entity(target)
	
	# Регистрируем труп
	level.register_entity_at_position(corpse, target_tile_pos)
	
	# Добавляем труп на сцену
	entity.get_tree().current_scene.add_child(corpse)
	corpse.position = level.tile_to_local(target_tile_pos)
	
	# Удаляем саму сущность
	target.queue_free()


# Отменить атаку (для системы откатов)
func undo(level: Level) -> void:
	if target == null:
		return
	
	# Восстанавливаем HP цели
	target.hp = target_hp_before
	target.is_alive = true
	
	# TODO: Обработать случай, если цель превратилась в труп
	# Это сложный случай, требующий удаления трупа и восстановления сущности
