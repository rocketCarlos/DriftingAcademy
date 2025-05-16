extends Control

signal clicked_play
signal clicked_credits

func _on_play_button_button_clicked() -> void:
	clicked_play.emit()


func _on_credits_button_button_clicked() -> void:
	clicked_credits.emit()
