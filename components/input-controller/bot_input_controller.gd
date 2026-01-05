class_name BotInputController
extends InputControllerBase

var points: Array
var current_point = 0
var input_tween: Tween = null
@export var debug: bool = false

func _ready() -> void:
	points = get_tree().get_nodes_in_group("BotPoints")
	current_point = 0
	input = points[current_point].position

	if not debug:
		$VirtualInputDebug.hide()
	
func _physics_process(_delta: float) -> void:
	if debug:
		$VirtualInputDebug.global_position = input
		
		
func _on_points_detector_area_entered(_area: Area2D) -> void:
	current_point = (current_point + 1) % points.size()
	if input_tween:
		input_tween.kill()

	input_tween = create_tween()

	var new_virtual_position = points[current_point].position
	var interpolation_time: float
	var min_interpolation: float = 0.2
	var max_interpolation: float = 1

	interpolation_time = (
		clampf(
			lerpf(
				min_interpolation,
				max_interpolation,
				inverse_lerp(0.0, 1500.0, input.distance_to(new_virtual_position))
			),
			min_interpolation,
			max_interpolation
		)
	)

	(input_tween
		.tween_property(self, "virtual_input", new_virtual_position, interpolation_time)
		.set_trans(Tween.TRANS_LINEAR)
		.set_ease(Tween.EASE_OUT)
	)
