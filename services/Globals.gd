extends Node
"""
Script to hold global variables, signal and node references
"""

"""
Game state enums
"""
enum GAME_MODE {
	TIME_TRIAL,
}
var current_gamemode: GAME_MODE

"""
Node references
"""
var circuit_tileset: Node

"""
Info variables
"""
var car_speeed: float = 0
const total_laps_gamemode: Dictionary[GAME_MODE, int] = {
	GAME_MODE.TIME_TRIAL: 4
}

"""
Flow control signals
"""
signal race_restarted
signal lap_completed
signal race_started
signal race_ended
