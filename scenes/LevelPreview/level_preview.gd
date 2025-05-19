extends Control

@onready var level_img = $Level
@onready var level_label = $LevelName

var selected_idx: int = 0

@export var images: Array[Texture]
@export var level_names: Array[String]

func _ready() -> void:
	level_img.texture = images[0]
	level_label.text = level_names[0]

func _on_left_button_button_clicked() -> void:
	selected_idx = (selected_idx + images.size() - 1) % images.size()
	level_img.texture = images[selected_idx]
	level_label.text = level_names[selected_idx]


func _on_right_button_button_clicked() -> void:
	selected_idx = (selected_idx + 1) % images.size()
	level_img.texture = images[selected_idx]
	level_label.text = level_names[selected_idx]
