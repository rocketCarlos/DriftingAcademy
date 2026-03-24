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

	var current_position_coordinate = Globals.circuit_tileset.local_to_map(Globals.circuit_tileset.to_local(parent.global_position))

	if current_position_coordinate != last_position_coordinate:
		last_position_coordinate = current_position_coordinate
		_update_virtual_input(current_position_coordinate, (parent as CharacterBody2D).velocity)


func _update_virtual_input(position: Vector2i, velocity: Vector2) -> void:
	if input_tween:
		input_tween.kill()

	input_tween = create_tween()

	var new_virtual_position = _compute_virtual_input(position, velocity)

	(input_tween
		.tween_property(self, "input", new_virtual_position, 0.1)
		.set_trans(Tween.TRANS_LINEAR)
		.set_ease(Tween.EASE_OUT)
	)


func _compute_virtual_input(position: Vector2i, velocity: Vector2) -> Vector2:
	var depth = clampi(int(lerp(0.0, 7.0, inverse_lerp(50, 300, velocity.length()))), 1, 7)

	return (
		Globals.circuit_tileset.to_global(
			Globals.circuit_tileset.map_to_local(_select_best_neighbour(position, depth))
		)
	)


func _select_best_neighbour(initial_position: Vector2i, depth: int) -> Vector2:
	cell_path = []
	var best_cell: Vector2
	for i in range(depth):
		var neighbours: Array[Vector2i] = Globals.circuit.get_cell_neighbours(initial_position)
		best_cell = neighbours[0] if neighbours[0] not in cell_path else neighbours[1]
		for cell in neighbours:
			if cell in cell_path:
				# skip already visited cells
				continue
			if Globals.circuit.is_cell_road(best_cell):
				if (
					Globals.circuit.is_cell_road(cell)
					and (Globals.circuit.progress_record[cell] < Globals.circuit.progress_record[best_cell])
				):
					best_cell = cell
			elif (
				(Globals.circuit.progress_record[cell] < Globals.circuit.progress_record[best_cell])
				or Globals.circuit.is_cell_road(cell)
			):
				best_cell = cell
		initial_position = best_cell
		cell_path.append(best_cell)


	return best_cell
