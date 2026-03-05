extends Entity
class_name Obstacle

# === ПАРАМЕТРЫ ===
# Является ли этот объект трупом
@export var is_corpse: bool = false

# Имя сущности, которая стала трупом (для отображения)
var corpse_name: String = ""


func _ready() -> void:
	super._ready()
	# Препятствия не участвуют в ходах
	max_ap = 0
	current_ap = 0
	# Обычно 1 HP для уничтожения
	max_hp = 1
	hp = 1


# Препятствия не ходят
func _start_turn() -> void:
	emit_signal("turn_finished")


# === ИНФОРМАЦИЯ ===

func get_display_name() -> String:
	if is_corpse:
		if corpse_name != "":
			return "Труп (" + corpse_name + ")"
		return "Труп"
	return "Препятствие"


# Создать препятствие-труп из сущности
static func create_corpse(from_entity: Entity) -> Obstacle:
	var corpse: Obstacle = Obstacle.new()
	corpse.is_corpse = true
	corpse.corpse_name = from_entity.get_display_name()
	corpse.max_hp = 1
	corpse.hp = 1
	corpse.tile_position = from_entity.tile_position
	corpse.position = from_entity.position
	return corpse
