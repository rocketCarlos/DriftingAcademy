@tool
extends Node2D

@export_tool_button("Computar pesos") var compute_progress_button = _compute_progress_wrapper
var _computing: bool = false
var _progress_thread: Thread
signal _thread_ended
# tileset coordinate -> distance to end
@export_storage var progress_record: Dictionary[Vector2i, float] = {}
var sqrt2 = sqrt(2.0)
var max_weight: float = 0.0
@export var CellWeightScene: PackedScene

@onready var circuit_tileset = $RoadLayout
@onready var decoration_tileset = $RoadLayout/DecorationLayout
@onready var initial_colliders = $InitialColliders
@onready var starting_grid = $StartingGrid
@onready var race_checkpoints = $RaceCheckpoints
@onready var ghost = $Ghost
@onready var debug_items = $DebugItems

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
	_progress_thread.wait_to_finish()
	_computing = false
	call_deferred("draw_cell_weights")
	notify_property_list_changed()

func _compute_progress() -> void:
	progress_record = {}
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

	# set finish cells as 0 weight
	for cell in finish_cells:
		progress_record.set(cell, 0.0)

	var initial_offset = (
		Vector2i(1, 0) if initial_car_rotation == DIRECTION.LEFT else
		Vector2i(-1, 0) if initial_car_rotation == DIRECTION.RIGHT else
		Vector2i(0, 1) if initial_car_rotation == DIRECTION.DOWN else
		Vector2i(0, -1)
	)
	# cells to check, FIFO queue. Array[Dictionary[Vector21, float]] -> list of coords and its weight
	var cell_queue = []

	# init cell_queue with cells at the oposite side of the finish lines
	for finish_cell in finish_cells:
		var new_cell = finish_cell + initial_offset
		if _is_cell_valid(new_cell):
			cell_queue.append({new_cell: 1.0})

	# compute weight of the full track
	max_weight = 0.0
	while len(cell_queue) > 0:
		var parent_cell = cell_queue.pop_front()
		var parent_cell_coords = parent_cell.keys()[0]

		# TODO: checkear algoritmo. Se están produciendo mejores celdas y se están skipeando.
		# contemplar tratar el cell queue con un set adicional para tener siempre en la cola la
		# mejor versión de cada celda
		if progress_record.has(parent_cell_coords):
			continue

		var children_cells = _get_cell_neighbours(parent_cell_coords)
		for child in children_cells:
			if not progress_record.has(child): # should always be true?
				var cell_weight = parent_cell[parent_cell_coords] + (
								1.0 if parent_cell_coords.x == child.x or parent_cell_coords.y == child.y
								else sqrt2
							)
				# insert in cell_queue treating it as a priority queue
				cell_queue.insert(
					cell_queue.bsearch_custom(
							{ child: cell_weight },
							func(a, b): return a[a.keys()[0]] < b[b.keys()[0]],
							true
						),
						{ child: cell_weight }
				)
				if cell_weight > max_weight:
					max_weight = cell_weight

		progress_record.merge(parent_cell)

	call_thread_safe("emit_signal", "_thread_ended")


func _get_finish_cells_in_direction(starting_cell: Vector2i, direction: Vector2i) -> Array[Vector2i]:
	var done: bool = false
	var current_cell: Vector2i = starting_cell
	var result: Array[Vector2i] = []

	while not done:
		var next_cell: Vector2i = current_cell + direction
		var atlas_coords = circuit_tileset.get_cell_atlas_coords(next_cell)
		if not atlas_coords == ATLAS_FINISH_COORDS:
			if _is_cell_valid(next_cell):
				result.append(next_cell)
			else:
				done = true
		current_cell = next_cell

	return result

"""
Get all cell neighbours that are not obstacles
"""
func _get_cell_neighbours(cell_position: Vector2i) -> Array[Vector2i]:
	var neighbours: Array[Vector2i] = []

	var directions = [
		Vector2i(-1, 1), # top left
		Vector2i(0, 1), # top
		Vector2i(1, 1), # top right
		Vector2i(-1, 0), # left
		Vector2i(1, 0), # right
		Vector2i(-1, -1), # bottom left
		Vector2i(0, -1), # bottom
		Vector2i(1, -1), # bottom right
	]

	for direction in directions:
		var cell_to_check = cell_position + direction
		if _is_cell_valid(cell_to_check):
			neighbours.append(cell_to_check)

	return neighbours

"""
Returns true if cell is valid and has no obstacle above. False otherwise
"""
func _is_cell_valid(cell_position: Vector2i) -> bool:
	return (
		true if (
			circuit_tileset.get_cell_atlas_coords(cell_position) != Vector2i(-1, -1) and
			decoration_tileset.get_cell_source_id(cell_position) == -1
		)
		else false
	)

"""
Draws labels for cell weights
"""
func draw_cell_weights() -> void:
	for child in debug_items.get_children():
		child.queue_free()
	for key in progress_record.keys():
		var indicator = CellWeightScene.instantiate()
		indicator.set_weight(progress_record[key], max_weight)
		indicator.position = circuit_tileset.to_global((circuit_tileset.map_to_local(key))) + Vector2(-16.0, -16.0)
		debug_items.call_deferred("add_child", indicator)

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
