extends Control

@onready var car_position = $car_position
@onready var level_preview = $LevelPreview

signal clicked_go_drift(level: int)

func _on_go_drift_button_clicked() -> void:
	clicked_go_drift.emit(level_preview.selected_idx)
