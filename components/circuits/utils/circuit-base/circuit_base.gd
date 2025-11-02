extends Node2D

@onready var circuit_tileset = $RoadLayout
@onready var initial_colliders = $InitialColliders
@onready var starting_grid = $StartingGrid

enum DIRECTION {LEFT, RIGHT, UP, DOWN}
@export var initial_car_rotation: DIRECTION = DIRECTION.RIGHT

#TODO: the undermentioned things
"""
Idea: find onready var through code in the ready function. Add functionality here to standarize
things like:
	- check that the circuit has a road layout (and obstacles?)
	- check that the circuit has checkpoints
	- optionally check that initial colliders exist?
	- manage restarting
	- manage cars possible initial positions


Circuit base -> use this as the base node for any circuit.

USAGE:
	1. Add a tileset to RoadLayout and ObstaclesLayout nodes and draw the circuit
	2. Add 2D nodes to StartingGrid node and place them where you want the cars to start. Name them
	with a single number representing the grid order (i.e. the node named "3" represents the third
	place in the starting grid)
	3. Add CollisionShape2D nodes to RaceChekpoint node following the instructions of the scene.
	4. Add a CollisionPolygon2D node to InitialColliders that will be used prevent the user from
	driving backwards at the race start in some game modes. It should be placed behind the last
	available position in the StartingGrid
	5. Select the initial rotation of cars using the Initial Car Rotation exported variable
"""

var car_initial_position
var car_initial_rotation

func initialize() -> void:
	if not initial_colliders:
		initial_colliders = get_node("InitialColliders")

	initial_colliders.process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	Globals.circuit_tileset = circuit_tileset
	Globals.race_started.connect(_on_race_started)
	Globals.race_restarted.connect(_on_race_restarted)

"""
Returns the position coordinates of the given position of the StartingGrid
"""
func get_grid_position(pos: int) -> Vector2:
	if not starting_grid:
		starting_grid = get_node("StartingGrid")

	return starting_grid.get_child(pos).position


"""
Returns the circuit's initial rotation for cars, in radians
"""
func get_initial_rotation() -> float:
	match initial_car_rotation:
		DIRECTION.UP:
			return 0
		DIRECTION.RIGHT:
			return PI/2
		DIRECTION.DOWN:
			return PI
		DIRECTION.LEFT:
			return -PI/2
		_:
			return 0

func _on_race_started() -> void:
	initial_colliders.process_mode = Node.PROCESS_MODE_DISABLED

func _on_race_restarted() -> void:
	initialize()
