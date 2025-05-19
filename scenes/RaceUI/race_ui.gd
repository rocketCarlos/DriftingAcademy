extends Control

@onready var time_label = $TimeLabel
@onready var speed_label = $Speed

var track_time: bool = false
var elapsed_time: float = 0.0

func _ready() -> void:
	Globals.lap_completed.connect(_on_lap_completed)
	Globals.first_lap_start.connect(_on_first_lap_start)

func _process(delta: float) -> void:
	if track_time:
		elapsed_time += delta
		time_label.text = str(elapsed_time).pad_decimals(2)
		if Globals.car_speeed > 300:
			Globals.car_speeed = 300
		speed_label.text = str(ceili(Globals.car_speeed))

func _on_lap_completed():
	print(time_label.text)
	elapsed_time = 0

func _on_first_lap_start() -> void:
	track_time = true
	elapsed_time = 0.0
