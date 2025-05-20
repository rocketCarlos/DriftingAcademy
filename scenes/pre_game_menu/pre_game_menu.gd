extends Control

@onready var level_preview = $LevelPreview
@onready var skin_texture = $SkinSelector/TextureRect

signal clicked_go_drift(level: int)
signal clicked_go_back


var car_skins = [
	preload("res://assets/cars/sportscar1.png"), 
	preload("res://assets/cars/f1car.png"), 
	preload("res://assets/cars/pointy.png"), 
	preload("res://assets/cars/chev.png")
	]
var current_skin = 0

func _ready() -> void:
	skin_texture.texture = car_skins[current_skin]
	
#region signal functions
func _on_go_drift_button_clicked() -> void:
	Globals.car_skin = current_skin
	clicked_go_drift.emit(level_preview.selected_idx)
	
	

func _on_left_button_clicked() -> void:
	current_skin = (current_skin + car_skins.size() - 1) % car_skins.size()
	skin_texture.texture = car_skins[current_skin]


func _on_right_button_clicked() -> void:
	current_skin = (current_skin + 1) % car_skins.size()
	skin_texture.texture = car_skins[current_skin]


func _on_go_back_button_clicked() -> void:
	clicked_go_back.emit()

	
#endregion
