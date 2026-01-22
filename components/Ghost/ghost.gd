extends Sprite2D

var samples: Array
var process_samples: bool = false
var current_sample_index: int = 0
var timer: float = 0.0


func _ready() -> void:
	if SaveManager.current_save:
		samples = SaveManager.current_save.ghost_samples
		if samples.size() == 0:
			hide()
	else:
		hide()


func _process(delta: float) -> void:
	if not process_samples or current_sample_index >= samples.size():
		return

	var sample = samples[current_sample_index]

	while sample.t < timer and current_sample_index + 1 < samples.size():
		current_sample_index += 1
		sample = samples[current_sample_index]

	var prev_sample = samples[current_sample_index - 1] if current_sample_index > 0 else samples[current_sample_index]

	var weight = inverse_lerp(prev_sample.t, sample.t, timer)
	position.x = lerp(prev_sample.x, sample.x, weight)
	position.y = lerp(prev_sample.y, sample.y, weight)
	rotation = lerp(prev_sample.rot, sample.rot, weight)

	timer += delta


func start() -> void:
	if samples.size() > 0:
		show()
	else:
		hide()

	process_samples = true
	timer = 0.0
	current_sample_index = 0
