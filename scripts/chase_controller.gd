class_name ChaseController
extends Controller

# Контроллер преследования: враг идёт к игроку


# Получить следующее действие (движение к игроку)
func get_next_action() -> Action:
        var move_dir: Vector2i = _calculate_move_direction()
        
        if move_dir != Vector2i.ZERO:
                return MoveAction.new(entity, move_dir)
        
        return null


# У врага пока одно действие за ход
func has_more_actions() -> bool:
        return false


# Рассчитать направление движения к ближайшему герою
func _calculate_move_direction() -> Vector2i:
        if not entity.current_level:
                return Vector2i.ZERO
        
        # Используем актуальную позицию из _occupied
        var my_pos: Vector2i = entity.current_level.get_entity_position(entity)
        var target_pos: Vector2i = entity.current_level.get_nearest_hero_position(my_pos)
        var direction: Vector2i = target_pos - my_pos
        
        var move_dir: Vector2i = Vector2i.ZERO
        
        # Приоритет: сначала по X, потом по Y
        if direction.x != 0:
                move_dir.x = sign(direction.x)
        elif direction.y != 0:
                move_dir.y = sign(direction.y)
        
        return move_dir
