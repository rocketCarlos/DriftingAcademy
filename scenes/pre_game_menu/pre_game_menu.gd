extends Control

@onready var car_position = $car_position

signal clicked_go_drift

func _on_go_drift_button_clicked() -> void:
	clicked_go_drift.emit()
