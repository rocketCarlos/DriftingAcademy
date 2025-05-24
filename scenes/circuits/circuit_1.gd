extends Node2D

@onready var circuit_tileset = $road_layout
@onready var initial_colliders = $InitialColliders
@onready var car = $Car

var car_initial_position
var car_initial_rotation

func _ready() -> void:
	Globals.circuit_tileset = circuit_tileset
	Globals.first_lap_start.connect(_on_first_lap_start)
	Globals.all_laps_completed.connect(_on_all_laps_completed)
	Globals.level_restart.connect(_on_level_restart)
	car.update_skin(Globals.car_skin)
	car_initial_position = car.position
	car_initial_rotation = car.rotation
	

func _on_first_lap_start() -> void:
	initial_colliders.process_mode = Node.PROCESS_MODE_DISABLED

func _on_all_laps_completed(all_times, total_times) -> void:
	queue_free()

func _on_level_restart() -> void:
	initial_colliders.process_mode = Node.PROCESS_MODE_ALWAYS
	car.position = car_initial_position
	car.rotation = car_initial_rotation
	car.velocity = Vector2.ZERO
	
