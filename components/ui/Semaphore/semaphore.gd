extends AnimatedSprite2D

@onready var sfx: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	Globals.race_aborted.connect(_on_race_aborted)


func _on_race_aborted():
	queue_free()

func _on_animation_finished() -> void:
	queue_free()


func _on_frame_changed() -> void:
	if frame == sprite_frames.get_frame_count("default") -1:
		Globals.race_started.emit(self)
	sfx.play(0.96*(frame-1))
	await get_tree().create_timer(0.96).timeout
	sfx.stop()
