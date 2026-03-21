@tool
extends ColorRect

const ALPHA: float = 0.663

func set_weight(value: float, max_weight: float) -> void:
	$Label.text = str(value).pad_decimals(1)
	var break_point = max_weight / 2.0
	color = Color(
		1.0 if value > break_point else inverse_lerp(0.0, break_point, value),
		1.0 if value <= break_point else 1.0-inverse_lerp(break_point, max_weight, value),
		0.0,
		ALPHA
	)
