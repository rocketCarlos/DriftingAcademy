extends Node2D
"""
Step to add a new circuit:
	1. Create a new Sprite2D node and set the circuit's preview as the texture
	2. Add a new value in the enum and a new entry in the circuits dictionary with the new enum
	value and the preloaded circuit

	Note: see circuit_base for info on creating circuits
"""

signal load_current_circuit

var current_circuit: CIRCUIT_NAME

enum CIRCUIT_NAME {
	DRIFTINGS_CRADLE,
	SERPENTS_DESCENT,
	UNDER_CONSTRUCTION,
}

@onready var circuits_thumbnails: Dictionary[CIRCUIT_NAME, Node] = {
	CIRCUIT_NAME.DRIFTINGS_CRADLE: $DriftingsCradle,
	CIRCUIT_NAME.SERPENTS_DESCENT: $SerpentsDescent,
	CIRCUIT_NAME.UNDER_CONSTRUCTION: $UnderConstruction,
}

var circuit_scenes: Dictionary[CIRCUIT_NAME, Resource] = {
	CIRCUIT_NAME.DRIFTINGS_CRADLE: preload("uid://cu0ud7us0w8n"),
	CIRCUIT_NAME.SERPENTS_DESCENT: preload("uid://lqo8da81rpvg"),
}

"""
Sets the current circuit and returns de thumbnail of that circuit
"""
func set_circuit(circuit_name: CIRCUIT_NAME) -> Sprite2D:
	current_circuit = circuit_name
	return circuits_thumbnails.get(circuit_name)


"""
Gets the current circuit
"""
func get_and_initialize_current_circuit() -> Node:
	var circuit = circuit_scenes.get(current_circuit).instantiate()
	circuit.initialize()
	return circuit
