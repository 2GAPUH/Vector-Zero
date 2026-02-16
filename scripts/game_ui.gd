extends Control

@onready var turn_label: Label = $MarginContainer/VBoxContainer/Label

func update_turn_text(entity_name: String) -> void:
	turn_label.text = "Ход: " + entity_name
