extends Entity
class_name Obstacle

# === ПАРАМЕТРЫ ===
# Является ли этот объект трупом
@export var is_corpse: bool = false

# Имя сущности, которая стала трупом (для отображения)
var corpse_name: String = ""

# Путь к сцене трупа
const CORPSE_SCENE_PATH: String = "res://scenes/entities/Corpse.tscn"


func _ready() -> void:
        super._ready()
        # Препятствия не участвуют в ходах
        max_ap = 0
        current_ap = 0
        # Обычно 1 HP для уничтожения
        if max_hp == 2:  # дефолтное значение от Entity
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


# === СОЗДАНИЕ ТРУПА ===

# Создать препятствие-труп из сущности (загружает сцену)
static func create_corpse_instance(from_entity: Entity) -> Obstacle:
        var corpse_scene: PackedScene = load(CORPSE_SCENE_PATH)
        if corpse_scene == null:
                push_error("Не удалось загрузить сцену трупа: " + CORPSE_SCENE_PATH)
                return null
        
        var corpse: Obstacle = corpse_scene.instantiate() as Obstacle
        corpse.is_corpse = true
        corpse.corpse_name = from_entity.get_display_name()
        corpse.tile_position = from_entity.tile_position
        corpse.position = from_entity.position
        
        return corpse


# Создать препятствие-труп программно (без сцены)
static func create_corpse(from_entity: Entity) -> Obstacle:
        var corpse: Obstacle = Obstacle.new()
        corpse.is_corpse = true
        corpse.corpse_name = from_entity.get_display_name()
        corpse.max_hp = 1
        corpse.hp = 1
        corpse.tile_position = from_entity.tile_position
        corpse.position = from_entity.position
        
        return corpse
