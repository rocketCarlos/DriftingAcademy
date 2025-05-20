extends Control

signal clicked_go_back

func _on_go_back_button_clicked() -> void:
	clicked_go_back.emit()
