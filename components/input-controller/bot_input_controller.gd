class_name BotInputController
extends InputControllerBase

var input_tween: Tween = null
@export var debug: bool = false
enum THINKING_MODES {NEXT_CELL_SIMULATION, CELL_PATH, ADJUSTED_CELL_PATH}
@export var thinking_mode: THINKING_MODES = THINKING_MODES.ADJUSTED_CELL_PATH
@export_range(0.0, 500, 0.1) var random_offset: float = 100.0

var last_position = null # Vector2 or null last position WHERE INPUT COMPUTING WAS DONE
var cell_path: Array[Vector2i]

@onready var line_to_input: Line2D = $LineToInput
@onready var velocity: Line2D = $Velocity
@onready var neighbour_path: Line2D = $NeighbourPath

var movement_controller
var driving_bias: float

func _ready() -> void:
	super()

	movement_controller = parent.get_node("MovementController")

	line_to_input.add_point(Vector2(0.0, 0.0))
	velocity.add_point(Vector2(0.0, 0.0))
	driving_bias = randf() * 10000

	if not debug:
		line_to_input.hide()
		velocity.hide()
		neighbour_path.hide()
	else:
		pass

func _physics_process(delta: float) -> void:
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

	if not last_position or abs(parent.global_position - last_position).length() > 8.0:
		last_position = parent.global_position
		_update_virtual_input(current_position_coordinate, delta)


func _update_virtual_input(position: Vector2i, delta: float) -> void:
	if input_tween:
		input_tween.kill()

	input_tween = create_tween()
#
	var new_virtual_position = _apply_randomness(_compute_virtual_input(position, delta), random_offset)

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
		neighbours = _reorder_cells(neighbours, initial_position)
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
			elif (not initial_weight - Globals.circuit.progress_record[cell] > 100) and (not Globals.circuit.progress_record[best_cell] - Globals.circuit.progress_record[cell] > 100):
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
	var speed: float =  parent.velocity.length()
	var depth: int = int(lerp(0.0, 4.0, inverse_lerp(50, 300, speed)))
	depth = depth if depth > 0 else 1

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
	var depth = roundi(remap(max(speed, 75.0), 75.0, 300.0, 1.0, 5.0))

	# get desired cell that pushes us through the best path
	var best_neighbour_global_position: Vector2 = Globals.circuit_tileset.to_global(
			Globals.circuit_tileset.map_to_local(_select_best_neighbour(position, depth))
		)

	var final_input = best_neighbour_global_position
	if depth > 3:
		# adjust input based on angle between desired cell and current velocity to counter inertia
		var u: Vector2 = best_neighbour_global_position - parent.global_position
		var v: Vector2 = parent.velocity

		var theta = u.angle_to(v)

		final_input = parent.global_position + u.rotated(-2.0*theta)

	return final_input


func _rotate_vector(vector: Vector2, rads: float) -> Vector2:
	"""
	given a vector, rotate it `rads` radians
	"""
	return Vector2(
			vector.x*cos(rads) - vector.y*sin(rads),
			vector.x*sin(rads) + vector.y*cos(rads)
		)

func _reorder_cells(cells: Array[Vector2i], center: Vector2i) -> Array[Vector2i]:
	"""
	Given an array of center's cell adyacent cells, reorder it based on velocity's direction
	"""
	var effective_velocity = (
		parent.velocity.normalized()
		if parent.velocity.length_squared() > 0.001
		else Vector2.UP.rotated(parent.rotation)
	)

	var dir = effective_velocity.normalized()

	cells.sort_custom(func(a:Vector2i, b:Vector2i):
		var da = (Vector2(a - center)).normalized().dot(dir)
		var db = (Vector2(b - center)).normalized().dot(dir)

		return da > db
	)

	return cells


func _apply_randomness(target_position: Vector2, radius: float) -> Vector2:
	"""
	Apply random offset to input vector based on provided radius
	"""
	var from_body = target_position - parent.global_position
	var perpendicular = from_body.normalized().orthogonal()

	var noise = FastNoiseLite.new()
	var offset = noise.get_noise_1d((Time.get_ticks_msec() + driving_bias) * 0.01) * radius
	print(offset)

	return target_position + perpendicular * offset
