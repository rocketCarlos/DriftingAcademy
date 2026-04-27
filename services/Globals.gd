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

"""
Node references
"""
var circuit: Node
var circuit_tileset: Node
var car: Node

"""
Info variables
"""
var car_speeed: float = 0
const total_laps_gamemode: Dictionary[GAME_MODE, int] = {
	GAME_MODE.TIME_TRIAL: 4,
	GAME_MODE.VS_MACHINE: 0
}

"""
Flow control signals
"""
signal race_restarted
signal lap_completed(object: Node2D)
signal race_started(object: Node2D)
signal race_ended
