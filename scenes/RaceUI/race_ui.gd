extends Control

@onready var time_label = $TimeLabel
@onready var speed_label = $Speed
@onready var lap_label = $Lap/LapCount

@export var total_laps: int = 5
var current_lap = 1

var track_time: bool = false
var elapsed_time: float = 0.0
var total_time: float = 0.0

var all_times: Array[String]

func _ready() -> void:
	Globals.lap_completed.connect(_on_lap_completed)
	Globals.first_lap_start.connect(_on_first_lap_start)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Restart"):
		restart()
		Globals.level_restart.emit()
	
	if track_time:
		elapsed_time += delta
		time_label.text = str(elapsed_time).pad_decimals(2)
		if Globals.car_speeed > 300:
			Globals.car_speeed = 300
		speed_label.text = str(ceili(Globals.car_speeed))

func restart() -> void:
	track_time = false
	time_label.text = 'Cross the finish line to start!'
	speed_label.text = '0'
	current_lap = 1
	lap_label.text = '1/' + str(total_laps)
	all_times = []


func _on_lap_completed():
	print(time_label.text)
	all_times.push_back(time_label.text)
	total_time += elapsed_time
	elapsed_time = 0
	if current_lap == total_laps:
		Globals.all_laps_completed.emit(all_times, str(total_time).pad_decimals(2))
		restart()
	else:
		current_lap += 1
		lap_label.text = str(current_lap) + '/' + str(total_laps)
		

func _on_first_lap_start() -> void:
	track_time = true
	elapsed_time = 0.0
	total_time = 0.0
