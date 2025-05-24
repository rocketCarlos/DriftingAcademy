extends Area2D

var finish_line_start: bool = true # whether it is the first time the player crosses the finish line
var total_checkpoints: int = 6
var current_checkpoint: int = 0

func _ready() -> void:
	Globals.level_restart.connect(_on_level_restart)

func _on_race_checkpoints_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if local_shape_index == 0 and finish_line_start:
		finish_line_start = false
		Globals.first_lap_start.emit()
		
	if current_checkpoint + 1 == local_shape_index:
		current_checkpoint += 1
		
	if current_checkpoint + 1 == total_checkpoints and local_shape_index == 0:
		# this is a completed lap
		Globals.lap_completed.emit()
		current_checkpoint = 0

func _on_level_restart() -> void:
	finish_line_start = true
