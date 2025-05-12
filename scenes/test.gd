extends Node2D

# TODO: move all labels and UI logic to its own script
@onready var time_label = $UI/SubViewportContainer/SubViewport/RaceUI/TimeLabel
@onready var speed_label = $UI/SubViewportContainer/SubViewport/RaceUI/Speed

var time_elapsed: float = 0.0

func _ready() -> void:
	Globals.lap_completed.connect(_on_lap_completed)

func _process(delta: float) -> void:
	time_elapsed += delta
	time_label.text = str(time_elapsed).pad_decimals(2)
	# round to the closes multiple of 5
	speed_label.text = str(int(round(Globals.car_speeed / 5.0)) * 5)

func _on_lap_completed():
	print(time_label.text)
	time_elapsed = 0
