extends Node
"""
Script to hold global variables, signal and node references
"""

"""
Constants
"""
const BOUNCE_FACTOR: float = 0.3 # 0 = inelastic collision, 1 = perfect elastic collision

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
var car: Node

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
