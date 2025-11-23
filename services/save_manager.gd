extends Node

const SAVE_ROOT = "user://"
const TIME_TRIAL_SAVE_PATH = "time_trial/"

var current_save: TimeTrialCircuitSaveData

class TimeTrialCircuitSaveData:
	var circuit_name: String
	var lap_times: Array[float]
	# TODO: find some way to type this as Array[Dictionary] without errors in the load save function
	var ghost_samples: Array

	func _init(circuit_name: String, lap_times: Array[float], ghost_samples: Array) -> void:
		self.circuit_name = circuit_name
		self.lap_times = lap_times
		self.ghost_samples = ghost_samples


	func to_dict() -> Dictionary:
		return {
			"times": lap_times,
			"ghost_samples": ghost_samples
		}

	func get_total_time() -> float:
		return lap_times.reduce(func(accum, number): return accum + number)

func _ready() -> void:
	var dir_access = DirAccess.open(SAVE_ROOT)
	dir_access.make_dir_recursive(TIME_TRIAL_SAVE_PATH)

func save_time_trial(data: TimeTrialCircuitSaveData) -> bool:
	var save_file = FileAccess.open(
			SAVE_ROOT+TIME_TRIAL_SAVE_PATH+data.circuit_name+".dasf", FileAccess.WRITE
		)

	return save_file.store_line(JSON.stringify(data.to_dict(), "\t"))


func load_time_trial(circuit_name: String) -> TimeTrialCircuitSaveData:
	var savefile_name = SAVE_ROOT+TIME_TRIAL_SAVE_PATH+circuit_name+'.dasf'
	if not FileAccess.file_exists(savefile_name):
		push_warning("Savefile not found: ", circuit_name)
		return null

	var save_file = FileAccess.open(savefile_name, FileAccess.READ)
	var json_string = save_file.get_as_text()
	var json = JSON.new()

	# Check if there is any error while parsing the JSON string, skip in case of failure.
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		push_warning(
			"JSON Parse Error (", savefile_name, "): ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line()
		)
		return null
	# explicit conversion to Array[float] because casting json.data.get("times") as Array[float] won't work
	# TODO: ask in forum?
	var time_data: Array[float] = []
	for value in json.data.get("times"):
		time_data.push_back(value as float)

	var samples = json.data.get("ghost_samples")
	current_save = TimeTrialCircuitSaveData.new(circuit_name, time_data, samples if samples else [])

	return current_save
