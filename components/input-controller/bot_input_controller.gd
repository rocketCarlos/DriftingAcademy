class_name BotInputController
extends InputControllerBase

var input_tween: Tween = null
@export var debug: bool = false

var last_position_coordinate: Vector2i
var cell_path: Array[Vector2i]

@onready var line_to_input: Line2D = $LineToInput
@onready var velocity: Line2D = $Velocity
@onready var neighbour_path: Line2D = $NeighbourPath

func _ready() -> void:
	super()

	line_to_input.add_point(Vector2(0.0, 0.0))
	velocity.add_point(Vector2(0.0, 0.0))

	if not debug:
		line_to_input.hide()
		velocity.hide()
		neighbour_path.hide()
	else:
		pass

func _physics_process(_delta: float) -> void:
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

	var current_position_coordinate = Globals.circuit_tileset.local_to_map(Globals.circuit_tileset.to_local(parent.global_position))

	if current_position_coordinate != last_position_coordinate:
		last_position_coordinate = current_position_coordinate
		_update_virtual_input(current_position_coordinate)


func _update_virtual_input(position: Vector2i) -> void:
	if input_tween:
		input_tween.kill()

	input_tween = create_tween()

	var new_virtual_position = _compute_virtual_input(position)

	(input_tween
		.tween_property(self, "input", new_virtual_position, 0.1)
		.set_trans(Tween.TRANS_LINEAR)
		.set_ease(Tween.EASE_OUT)
	)


func _compute_virtual_input(position: Vector2i) -> Vector2:
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


func _select_best_neighbour(initial_position: Vector2i, depth: int) -> Vector2:
	cell_path = [initial_position]
	var initial_weight: float = Globals.circuit.progress_record[initial_position]
	var best_cell: Vector2i
	for i in range(depth):
		var neighbours: Array[Vector2i] = Globals.circuit.get_cell_neighbours(initial_position)
		best_cell = Vector2i(INF, INF) # init with invalid values
		for cell in neighbours:
			if cell in cell_path or Globals.circuit.progress_record[cell] == INF:
				# skip already visited or invalid cells
				continue
			elif best_cell.x == INF and best_cell.y == INF :
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


	if debug:
		neighbour_path.clear_points()
		for cell in cell_path:
			neighbour_path.add_point(
				neighbour_path.to_local(
					Globals.circuit_tileset.to_global(Globals.circuit_tileset.map_to_local(cell))
				)
			)

	return best_cell
