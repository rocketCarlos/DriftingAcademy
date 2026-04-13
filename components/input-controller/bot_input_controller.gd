class_name BotInputController
extends InputControllerBase

var input_tween: Tween = null
@export var debug: bool = false

var last_position_coordinate: Vector2i
var cell_path: Array[Vector2i]

func _ready() -> void:
	super()
	if not debug:
		$VirtualInputDebug.hide()

func _physics_process(_delta: float) -> void:
	if not last_position_coordinate:
		last_position_coordinate = Globals.circuit_tileset.local_to_map(Globals.circuit_tileset.to_local(parent.global_position))

	if debug:
		$VirtualInputDebug.global_position = input
		$VirtualInputDebug2.global_position = parent.global_position + parent.velocity

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
	var depth = clampi(int(lerp(0.0, 7.0, inverse_lerp(50, 300, parent.velocity.length()))), 1, 7)

	var best_neighbour_global_position: Vector2 = Globals.circuit_tileset.to_global(
			Globals.circuit_tileset.map_to_local(_select_best_neighbour(position, depth))
		)

	var u = best_neighbour_global_position - parent.global_position
	var v = parent.velocity

	var theta = rad_to_deg(acos(u.dot(v) / (u.length() * v.length())))

	if theta >= 90.0:
		print(theta)

	return best_neighbour_global_position


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


	return best_cell
