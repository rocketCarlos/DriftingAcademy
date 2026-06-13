extends Node
"""
Script to hold global variables, signal and node references
"""


"""
Game state enums
"""
enum GAME_MODE {
	TIME_TRIAL,
	VS_MACHINE
}
var current_gamemode: GAME_MODE

const GAMEMODE_LABELS: Dictionary[GAME_MODE, String] = {
	GAME_MODE.TIME_TRIAL: "Time trial",
	GAME_MODE.VS_MACHINE: "Vs. cpu"
}

enum DIFFICULTY {
	UNSET,
	ROOKIE,
	AMATEUR,
	PROFESSIONAL,
	CHAMPION,
}

const DIFFICULTY_LABELS: Dictionary[DIFFICULTY, String] = {
	DIFFICULTY.UNSET: "You shouldn't be seeing this",
	DIFFICULTY.ROOKIE: "Rookie",
	DIFFICULTY.AMATEUR: "Amateur",
	DIFFICULTY.PROFESSIONAL: "Professional",
	DIFFICULTY.CHAMPION: "Champion",
}

var current_difficulty: DIFFICULTY = DIFFICULTY.UNSET

"""
Node references
"""
var circuit: Node
var circuit_tileset: Node
var car: Node2D

"""
Info variables
"""
var car_speeed: float = 0
const total_laps_gamemode: Dictionary[GAME_MODE, int] = {
	GAME_MODE.TIME_TRIAL: 4,
	GAME_MODE.VS_MACHINE: 4
}

# Key: car / bot
# Value: v.x -> nº of laps, v.y = weight of current cell
# Car in 1st position is the one with the lowest weight among those with the greatest nº of laps
var race_scores: Dictionary[Node2D, Vector2]

func get_user_race_position() -> int:
	if not race_scores.get(car, null):
		return -1

	var user_laps = race_scores[car].x
	var user_weight = race_scores[car].y

	var position = 1

	for other in race_scores.keys():
		if other == car:
			continue

		var laps = race_scores[other].x
		var weight = race_scores[other].y

		if laps > user_laps or (laps == user_laps and weight < user_weight):
			position += 1

	return position


"""
Flow control signals
"""
signal race_restarted
signal lap_completed(object: Node2D)
signal race_started(object: Node2D)
signal race_ended


"""
Misc
"""
var bot_names = [
	"Razor",
	"Pixel",
	"Nova",
	"Echo",
	"Vortex",
	"Byte",
	"Ghost",
	"Blitz",
	"Kappa",
	"Zenith",
	"Drako",
	"Hydra",
	"Orion",
	"Mantis",
	"Zero",
	"Electro",
	"Bolt",
	"Cloud",
	"Panda",
	"Snake",
	"Wender",
	"Gambit"
]
