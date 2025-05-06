extends Area2D


var total_checkpoints: int = 6
var current_checkpoint: int

func _on_race_checkpoints_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if current_checkpoint == null:
		current_checkpoint = local_shape_index
	else:
		if current_checkpoint + 1 == local_shape_index:
			current_checkpoint += 1
			
		if current_checkpoint + 1 == total_checkpoints and local_shape_index == 0:
			# this is a completed lap
			Globals.lap_completed.emit()
			current_checkpoint = 0
