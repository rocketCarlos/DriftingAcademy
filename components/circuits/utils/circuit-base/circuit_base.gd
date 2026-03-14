@tool
extends Node2D

@export_tool_button("Computar pesos") var compute_progress_button = _compute_progress_wrapper
var _computing: bool = false
var _progress_thread: Thread
signal _thread_ended
# tileset coordinate -> distance to end
@export_storage var progress_record: Dictionary[Vector2i, float] = {}


@onready var circuit_tileset = $RoadLayout
@onready var decoration_tileset = $RoadLayout/DecorationLayout
@onready var initial_colliders = $InitialColliders
@onready var starting_grid = $StartingGrid
@onready var race_checkpoints = $RaceCheckpoints
@onready var ghost = $Ghost

enum DIRECTION {LEFT, RIGHT, UP, DOWN}
@export var initial_car_rotation: DIRECTION = DIRECTION.RIGHT
@export_range(0, 100, 1, "or_greater") var ATLAS_ID: int = 0
@export var ATLAS_FINISH_COORDS: Vector2i = Vector2i(6, 0)

"""
Circuit base -> use this as the base node for any circuit. You should rename the root node to get
better error traces

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
	if Globals.current_gamemode == Globals.GAME_MODE.TIME_TRIAL:
		if not initial_colliders:
			initial_colliders = get_node("InitialColliders")

		initial_colliders.process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	if not Engine.is_editor_hint():
		Globals.circuit_tileset = circuit_tileset
		Globals.race_started.connect(_on_race_started)
		Globals.race_restarted.connect(_on_race_restarted)

		# node structure checks
		if not starting_grid.get_child_count() > 0:
			push_error("No grid positions found for this circuit")
		else:
			var i = 1
			for child in starting_grid.get_children():
				if child.name != str(i):
					push_warning("Circuit's starting grid positions should be named after their index, not ", child.name)
				i += 1

		if not initial_colliders.get_child_count() > 0:
			push_error("No CollisionPolygon2D found for initial colliders")
		else:
			for child in initial_colliders.get_children():
				if not child.is_class("CollisionPolygon2D"):
					push_warning("Found an initial collider that is not a CollisionShape2D instance: ",
					child,
					". Node class is ", child.get_class())


func _validate_property(property: Dictionary):
	if property.name == "compute_progress_button":
		property.usage = PROPERTY_USAGE_EDITOR
		property.hint_string = "Computar pesos"
		if _computing:
			property.usage |= PROPERTY_USAGE_READ_ONLY
			property.hint_string = "Computando pesos..."


func _compute_progress_wrapper() -> void:
	_computing = true
	notify_property_list_changed()
	_progress_thread = Thread.new()
	_progress_thread.start(_compute_progress)
	await _thread_ended
	var result = _progress_thread.wait_to_finish()
	_computing = false
	notify_property_list_changed()

func _compute_progress() -> void:
	var finish_cells: Array[Vector2i] = circuit_tileset.get_used_cells_by_id(ATLAS_ID, ATLAS_FINISH_COORDS)

	# we need to add as finish cells those in the same axis with different atlas coords
	# this is, those "grass cells" outside the road that are also on the finish line axis
	# this assumes all finish cells share the same X or Y coord (no diagonal finish lines)
	# also assumes this finish axis encounters an obstacle before another road
	var finish_axis_direction: DIRECTION = DIRECTION.UP if finish_cells[0].x == finish_cells[1].x else DIRECTION.RIGHT

	finish_cells.append_array(
		_get_finish_cells_in_direction(finish_cells[0],
		Vector2i(1, 0) if finish_axis_direction == DIRECTION.RIGHT else Vector2i(0, -1))
	)
	finish_cells.append_array(
		_get_finish_cells_in_direction(finish_cells[0],
		Vector2i(-1, 0) if finish_axis_direction == DIRECTION.RIGHT else Vector2i(0, 1))
	)

	print(finish_cells)
	call_thread_safe("emit_signal", "_thread_ended")
	# inicializar set de celdas con los vecinos apropiados de la meta (los que van en el sentido
	# de las vueltas.
	# asignar peso de 1 a todas esas celdas
	# inicializar cola de celdas por registrar
	# loop:
	# si celda en set, ignorar
	# si no, añadir a set con peso +1 de su padre.
	# DEFINIR BIEN :D


func _get_finish_cells_in_direction(starting_cell: Vector2i, direction: Vector2i) -> Array[Vector2i]:
	var done: bool = false
	var current_cell: Vector2i = starting_cell
	var result: Array[Vector2i] = []

	while not done:
		var next_cell: Vector2i = current_cell + direction
		var atlas_coords = circuit_tileset.get_cell_atlas_coords(next_cell)
		if not atlas_coords == ATLAS_FINISH_COORDS:
			if atlas_coords == Vector2i(-1, -1) or decoration_tileset.get_cell_source_id(next_cell) != -1:
				done = true
			else:
				result.append(next_cell)
		current_cell = next_cell

	return result

func _get_cell_neighbours(cell_position: Vector2i) -> Array[Vector2i]:
	return []

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

func _on_race_started(object: Node2D) -> void:
	if object == Globals.car:
		initial_colliders.process_mode = Node.PROCESS_MODE_DISABLED
		ghost.start()

func _on_race_restarted() -> void:
	initialize()
	ghost.hide()
