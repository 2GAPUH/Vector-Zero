class_name Obstacle
extends Entity

# === ПРЕПЯТСТВИЕ (СТЕНЫ, ЯЩИКИ, ТРУПЫ) ===

# Является ли препятствие трупом
var is_corpse: bool = false

# Имя сущности, которой принадлежал труп
var corpse_of: String = ""


func _ready() -> void:
	super._ready()
	
	# Препятствия имеют 1 HP
	max_hp = 1
	current_hp = 1
	
	# Препятствия не участвуют в очереди ходов
	# Не добавляем способности


# === СОЗДАТЬ ТРУП ИЗ УМЕРШЕЙ СУЩНОСТИ ===
static func create_corpse(from_entity: Entity) -> Obstacle:
	var corpse: Obstacle = Obstacle.new()
	corpse.is_corpse = true
	corpse.corpse_of = from_entity.name
	corpse.max_hp = 1
	corpse.current_hp = 1
	return corpse


# === НАСТРОЙКА ПОЗИЦИИ ТРУПА ===
func setup_corpse(level: Level, pos: Vector2i) -> void:
	current_level = level
	tile_position = pos
	global_position = level.tile_to_local(pos)


# === ПРЕПЯТСТВИЯ НЕ ХОДЯТ ===
func _start_turn() -> void:
	# Препятствия не участвуют в ходах
	emit_signal("turn_finished")
