extends AnimatedSprite2D


func _on_animation_finished() -> void:
	queue_free()


func _on_frame_changed() -> void:
	if frame == sprite_frames.get_frame_count("default") -1:
		Globals.race_started.emit(self)
