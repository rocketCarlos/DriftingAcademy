extends Node

const SAMPLE_RATE = 20
const SAMPLE_INTERVAL = 1.0 / SAMPLE_RATE

var recording: bool = false
var samples: Array[Dictionary] = []
var time_accum: float = 999999.0 # big number to record the 0.0 sample
var run_time: float = 0.0


func _ready() -> void:
	Globals.race_started.connect(_on_race_started)
	Globals.race_restarted.connect(_on_race_restarted)
	Globals.race_ended.connect(_on_race_ended)
	Globals.race_aborted.connect(_on_race_ended)


func _process(delta):
	if not recording:
		return

	time_accum += delta

	if time_accum >= SAMPLE_INTERVAL:
		time_accum -= SAMPLE_INTERVAL
		_record_sample(run_time)

	run_time += delta

func _on_race_restarted():
	_on_race_started(null)

func _on_race_started(_object: Node2D) -> void:
	if Globals.car and Globals.current_gamemode == Globals.GAME_MODE.TIME_TRIAL:
		recording = true
		samples.clear()
		time_accum = 9999999.0 # big number to record the 0.0 sample
		run_time = 0.0


func _on_race_ended():
	recording = false


func _record_sample(t):
	samples.append({
		"t": t,
		"x": Globals.car.position.x,
		"y": Globals.car.position.y,
		"rot": Globals.car.rotation
	})
