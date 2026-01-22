class_name UserInputController
extends InputControllerBase

func get_input() -> Vector2:
	return parent.get_global_mouse_position()
