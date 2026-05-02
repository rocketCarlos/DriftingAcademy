extends Control

@onready var time_label = $Time
@onready var speed_label = $Speed
@onready var lap_label = $Lap/Count
@onready var restart_info = $RestartInfo

var total_laps: int
var current_lap = 1

var track_time: bool = false
var elapsed_time: float = 0.0
var total_time: float = 0.0

var all_times: Array[float]

func _ready() -> void:
	Globals.lap_completed.connect(_on_lap_completed)
	Globals.race_started.connect(_on_race_started)
	Globals.race_restarted.connect(_on_race_restarted)
	Globals.race_ended.connect(restart)
	total_laps = Globals.total_laps_gamemode[Globals.current_gamemode]
	restart()

	if Globals.current_gamemode == Globals.GAME_MODE.VS_MACHINE:
		time_label.text = ''
		restart_info.hide()


func _process(delta: float) -> void:
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


func _on_lap_completed(object: Node2D):
	if object == Globals.car:
		print(time_label.text)
		all_times.push_back(float(time_label.text))
		total_time += elapsed_time
		elapsed_time = 0
		if current_lap == total_laps:
			# TODO: let circuit manage total laps and race ended signal
			Globals.race_ended.emit()
		else:
			current_lap += 1
			lap_label.text = str(current_lap) + '/' + str(total_laps)


func _on_race_started(object: Node2D) -> void:
	if object == Globals.car:
		track_time = true
		elapsed_time = 0.0
		total_time = 0.0


func _on_race_restarted() -> void:
	restart()


func start_race_countdown() -> void:
	pass
