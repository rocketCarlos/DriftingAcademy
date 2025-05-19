extends Control

@onready var time_value_1 = $"TimePerLapValues/1"
@onready var time_value_2 = $"TimePerLapValues/2"
@onready var time_value_3 = $"TimePerLapValues/3"
@onready var time_value_4 = $"TimePerLapValues/4"
@onready var time_value_5 = $"TimePerLapValues/5"
@onready var time_total = $TimePerLapValues/TotalTime

#TODO: allow dynamic amount of laps

signal clicked_play_again
signal clicked_choose_level


func _on_play_again_button_clicked() -> void:
	clicked_play_again.emit()


func _on_choose_level_button_clicked() -> void:
	clicked_choose_level.emit()
