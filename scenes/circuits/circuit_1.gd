extends Node2D

@onready var circuit_tileset = $road_layout
@onready var initial_car_position = $InitialCarPosition
@onready var initial_colliders = $InitialColliders

func _ready() -> void:
	Globals.circuit_tileset = circuit_tileset
	Globals.first_lap_start.connect(_on_first_lap_start)

func _on_first_lap_start() -> void:
	initial_colliders.queue_free()
