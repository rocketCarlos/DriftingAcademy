extends Node2D

@onready var circuit_tileset = $road_layout

func _init() -> void:
	Globals.circuit_tileset = circuit_tileset.tile_set
