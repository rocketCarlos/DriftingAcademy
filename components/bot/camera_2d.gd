extends Camera2D

var engine_velocities = {
	0: 1.0,
	1: 0.25,
	2: 0.0
}

var current_game_speed: int = 0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_camera"):
		enabled = not enabled
		if enabled:
			make_current()

	if Input.is_action_just_pressed("toggle_game_speed"):
		current_game_speed = (current_game_speed + 1) % 3

		var next_speed = engine_velocities[current_game_speed]

		if next_speed == 0.0:
			get_tree().paused = true
		else:
			get_tree().paused = false
			Engine.time_scale = next_speed
