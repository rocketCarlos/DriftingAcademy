extends Node2D

@onready var circuit_tileset = $road_layout
@onready var initial_colliders = $InitialColliders
@onready var car = $Car

func _ready() -> void:
	Globals.circuit_tileset = circuit_tileset
	Globals.first_lap_start.connect(_on_first_lap_start)
	Globals.all_laps_completed.connect(_on_all_laps_completed)
	car.update_skin(Globals.car_skin)

func _on_first_lap_start() -> void:
	initial_colliders.queue_free()

func _on_all_laps_completed(all_times, total_times) -> void:
	queue_free()
