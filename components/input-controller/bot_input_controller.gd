class_name BotInputController
extends InputControllerBase

var input_tween: Tween = null
@export var debug: bool = false
enum THINKING_MODES {NEXT_CELL_SIMULATION, CELL_PATH, ADJUSTED_CELL_PATH}
@export var thinking_mode: THINKING_MODES = THINKING_MODES.NEXT_CELL_SIMULATION

var last_position_coordinate: Vector2i
var cell_path: Array[Vector2i]

@onready var line_to_input: Line2D = $LineToInput
@onready var velocity: Line2D = $Velocity
@onready var neighbour_path: Line2D = $NeighbourPath

var movement_controller

func _ready() -> void:
	super()

	movement_controller = parent.get_node("MovementController")

	line_to_input.add_point(Vector2(0.0, 0.0))
	velocity.add_point(Vector2(0.0, 0.0))

	if not debug:
		line_to_input.hide()
		velocity.hide()
		neighbour_path.hide()
	else:
		pass

func _physics_process(delta: float) -> void:
	if not last_position_coordinate:
		last_position_coordinate = Globals.circuit_tileset.local_to_map(Globals.circuit_tileset.to_local(parent.global_position))

	if debug:
		if line_to_input.get_point_count() > 1:
			line_to_input.remove_point(1)
		line_to_input.add_point(line_to_input.to_local(input))

		if velocity.get_point_count() > 1:
			velocity.remove_point(1)
		velocity.add_point(parent.velocity)
		velocity.global_rotation = 0

		neighbour_path.clear_points()
		for cell in cell_path:
			neighbour_path.add_point(
				neighbour_path.to_local(
					Globals.circuit_tileset.to_global(Globals.circuit_tileset.map_to_local(cell))
				)
			)

	var current_position_coordinate = (
		Globals.circuit_tileset.local_to_map(Globals.circuit_tileset.to_local(parent.global_position))
	)

	#if current_position_coordinate != last_position_coordinate:
	last_position_coordinate = current_position_coordinate
	_update_virtual_input(current_position_coordinate, delta)


func _update_virtual_input(position: Vector2i, delta: float) -> void:
	if input_tween:
		input_tween.kill()

	input_tween = create_tween()
#
	var new_virtual_position = _compute_virtual_input(position, delta)

	(input_tween
		.tween_property(self, "input", new_virtual_position, 0.1)
		.set_trans(Tween.TRANS_LINEAR)
		.set_ease(Tween.EASE_OUT)
	)

func _compute_virtual_input(position: Vector2i, delta: float) -> Vector2:
	match thinking_mode:
		THINKING_MODES.NEXT_CELL_SIMULATION:
			return _compute_next_cell_simulation(position, delta)
		THINKING_MODES.CELL_PATH:
			return _compute_cell_path(position)
		THINKING_MODES.ADJUSTED_CELL_PATH:
			return _compute_adjusted_cell_path(position)
		_:
			push_error("INVALID THINKING MODE")
			return Vector2()



func _select_best_neighbour(initial_position: Vector2i, depth: int) -> Vector2:
	cell_path = [initial_position]
	var initial_weight: float = Globals.circuit.progress_record[initial_position]
	var best_cell: Vector2i
	for i in range(depth):
		var neighbours: Array[Vector2i] = Globals.circuit.get_cell_neighbours(initial_position)
		best_cell = Vector2i(999999, 999999) # init with invalid values
		for cell in neighbours:
			if cell in cell_path or Globals.circuit.progress_record[cell] == INF:
				# skip already visited or invalid cells
				continue
			elif best_cell.x == 999999 and best_cell.y == 999999 :
				best_cell = cell

			if Globals.circuit.progress_record[cell] - initial_weight > 100: # assuming 100 is a big enough gap
				# special situation: car is right before the finish line and evaluating a cell
				# on the other side (has a much higher weight but it's "better")
				if Globals.circuit.progress_record[best_cell] - initial_weight > 100:
					if Globals.circuit.check_cell_boolean_property(best_cell, 'is_road'):
						if (
							Globals.circuit.check_cell_boolean_property(cell, 'is_road')
							and (Globals.circuit.progress_record[cell] < Globals.circuit.progress_record[best_cell])
						):
							best_cell = cell
					elif (
						(Globals.circuit.progress_record[cell] < Globals.circuit.progress_record[best_cell])
						or Globals.circuit.check_cell_boolean_property(cell, 'is_road')
					):
						best_cell = cell
				else:
					best_cell = cell

			# check if current cell is before finish line when we are already at the other side
			elif not initial_weight - Globals.circuit.progress_record[cell] > 100:
				if Globals.circuit.check_cell_boolean_property(best_cell, 'is_road'):
					if (
						Globals.circuit.check_cell_boolean_property(cell, 'is_road')
						and (Globals.circuit.progress_record[cell] < Globals.circuit.progress_record[best_cell])
					):
						best_cell = cell
				elif (
					(Globals.circuit.progress_record[cell] < Globals.circuit.progress_record[best_cell])
					or Globals.circuit.check_cell_boolean_property(cell, 'is_road')
				):
					best_cell = cell

		initial_position = best_cell
		cell_path.append(best_cell)

	return best_cell


func _compute_next_cell_simulation(position: Vector2i, delta: float) -> Vector2:
	var speed =  parent.velocity.length()
	var depth = clampi(int(lerp(0.0, 3.0, inverse_lerp(50, 300, speed))), 1, 3)

	var best_neighbour_position = Globals.circuit_tileset.to_global(
			Globals.circuit_tileset.map_to_local(_select_best_neighbour(position, depth))
		)

	var initial_direction = (best_neighbour_position-parent.global_position).normalized()
	var best_distance: float = (
		(
			movement_controller.simulate_move(initial_direction, delta) +
			parent.global_position
		).distance_squared_to(best_neighbour_position) # squared bc is faster and just need to compare
	)
	var initial_distance = best_distance
	var best_arc: float = 0.0
	var n_fragments = 16
	var arc = (2*PI)/n_fragments
	for i in range(n_fragments-1):
		var arc_to_test = i * arc
		var dist = (
			(
				movement_controller.simulate_move(_rotate_vector(initial_direction, arc_to_test), delta) +
				parent.global_position
			).distance_squared_to(best_neighbour_position)
		)

		if dist < best_distance:
			best_distance = dist
			best_arc = arc_to_test

	if initial_distance-best_distance < 3.0:
		# if difference too low, return best neighbour to avoid jittering
		return best_neighbour_position

	var final_direction = _rotate_vector(best_neighbour_position-parent.global_position, best_arc)
	return final_direction + parent.global_position


func _compute_cell_path(position: Vector2i) -> Vector2:
	var speed =  parent.velocity.length()
	var depth = clampi(int(lerp(0.0, 7.0, inverse_lerp(50, 300, speed))), 1, 7)

	# get desired cell that pushes us through the best path
	return Globals.circuit_tileset.to_global(
			Globals.circuit_tileset.map_to_local(_select_best_neighbour(position, depth))
		)


func _compute_adjusted_cell_path(position: Vector2i) -> Vector2:
	var speed =  parent.velocity.length()
	var depth = clampi(int(lerp(0.0, 7.0, inverse_lerp(50, 300, speed))), 1, 7)

	# get desired cell that pushes us through the best path
	var best_neighbour_global_position: Vector2 = Globals.circuit_tileset.to_global(
			Globals.circuit_tileset.map_to_local(_select_best_neighbour(position, depth))
		)

	var final_input = best_neighbour_global_position
	if speed > 250.0:
		# adjust input based on angle between desired cell and current velocity to counter inertia
		var u: Vector2 = best_neighbour_global_position - parent.global_position
		var v: Vector2 = parent.velocity

		var theta = acos(u.dot(v) / (u.length() * v.length()))

		# determine if u is left or right from v
		var is_desired_direction_left: bool = v.cross(u) < 0.0

		# get the new point by rotating u
		# var overturn: float = theta + pow(theta, 2.0) * 0.2
		var overturn: float = theta/4.0
		if not is_desired_direction_left:
			overturn = -overturn
		final_input = Vector2(
			best_neighbour_global_position.x*cos(overturn) - best_neighbour_global_position.y*sin(overturn),
			best_neighbour_global_position.x*sin(overturn) + best_neighbour_global_position.y*cos(overturn)
		)

	return final_input


func _rotate_vector(vector: Vector2, rads: float) -> Vector2:
	"""
	given a vector, rotate it `rads` radians
	"""
	return Vector2(
			vector.x*cos(rads) - vector.y*sin(rads),
			vector.x*sin(rads) + vector.y*cos(rads)
		)
