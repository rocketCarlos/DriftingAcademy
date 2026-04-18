extends Camera2D

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_camera"):
		enabled = not enabled
		if enabled:
			make_current()
