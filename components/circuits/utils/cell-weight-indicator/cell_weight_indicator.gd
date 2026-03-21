@tool
extends ColorRect

const ALPHA: float = 0.663

func set_weight(value: float, max_weight: float) -> void:
	$Label.text = str(value).pad_decimals(1)
	color = Color(
		1.0 if value <= (max_weight / 2.0) else inverse_lerp(0.0, max_weight, value),
		1.0 if value > (max_weight / 2.0) else 1.0-inverse_lerp(0.0, max_weight, value),
		0.0,
		ALPHA
	)
