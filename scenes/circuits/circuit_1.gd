extends Node2D

@onready var circuit_tileset = $road_layout
@onready var initial_car_position = $InitialCarPosition

func _ready() -> void:
	Globals.circuit_tileset = circuit_tileset
