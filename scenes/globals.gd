extends Node

var circuit_tileset

var car_speeed: float = 0

signal lap_completed

signal first_lap_start

signal all_laps_completed(all_times: Array[String], total_time: String)

var best_lap: float
var best_total: float
var car_skin: int
