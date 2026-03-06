extends Node2D
class_name HighlightLayer

# Цвет подсветки перемещения
var move_color: Color = Color(0.2, 1.0, 0.2, 0.4)

# Цвет подсветки атаки
var attack_color: Color = Color(1.0, 0.3, 0.3, 0.4)

# Список клеток для подсветки
var highlighted_cells: Array[Vector2i] = []

# Тип подсветки
var highlight_type: String = "move"

# Ссылка на уровень
var level: Level = null

# Размер тайла
var tile_size: Vector2i = Vector2i(16, 16)


func _draw() -> void:
	if highlighted_cells.is_empty():
		return
	
	for cell: Vector2i in highlighted_cells:
		var world_pos: Vector2 = level.tile_to_local(cell)
		
		# Выбираем цвет
		var color: Color = move_color
		if highlight_type == "attack":
			color = attack_color
		
		# Рисуем прямоугольник
		var rect: Rect2 = Rect2(world_pos - Vector2(tile_size.x / 2.0, tile_size.y / 2.0), Vector2(tile_size))
		draw_rect(rect, color, true)


# Установить клетки для подсветки
func set_cells(cells: Array[Vector2i], type: String = "move") -> void:
	highlighted_cells = cells
	highlight_type = type
	queue_redraw()


# Очистить подсветку
func clear_cells() -> void:
	highlighted_cells.clear()
	queue_redraw()


# Установить ссылку на уровень
func set_level(lvl: Level) -> void:
	level = lvl
	if level != null:
		tile_size = level.get_tile_size()
