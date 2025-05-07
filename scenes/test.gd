extends Node2D

@onready var time_label = $UI/SubViewportContainer/SubViewport/Control/TimeLabel

var time_elapsed: float = 0.0

func _ready() -> void:
	Globals.lap_completed.connect(_on_lap_completed)

func _process(delta: float) -> void:
	time_elapsed += delta
	time_label.text = str(time_elapsed).pad_decimals(2)

func _on_lap_completed():
	print(time_label.text)
	time_elapsed = 0
