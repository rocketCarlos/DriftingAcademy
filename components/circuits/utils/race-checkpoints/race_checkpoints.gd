extends Area2D

"""
Race Checkpoints

Use this scene to manage checkpoints in a circuit. To do so, add CollishionShape2D nodes as children
of this node. Each child will be considered a checkpoint and will be used to compute completed laps.
The first node will be considered the start/finish line
"""

var total_checkpoints: int
var current_checkpoint: Dictionary[Node2D, int]

func _ready() -> void:
	Globals.race_restarted.connect(_on_race_restarted)
	var children = get_children()
	total_checkpoints = children.size()

	if total_checkpoints == 0:
		push_error("No checkpoints found!")
	else:
		for child in children:
			if not child.is_class("CollisionShape2D"):
				push_warning("Found a checkpoint that is not a CollisionShape2D instance: ",
				child,
				". Node class is ", child.get_class())


func _on_race_checkpoints_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, local_shape_index: int) -> void:
	if local_shape_index == 0 and current_checkpoint.get(body) == null:
		# first time this car has crossed the finish/start line
		Globals.race_started.emit(body)
		current_checkpoint.set(body, 0)

	var checkpoint_index: int = current_checkpoint.get(body)
	if checkpoint_index != null:
		if checkpoint_index + 1 == local_shape_index:
			current_checkpoint.set(body, checkpoint_index + 1)

		if checkpoint_index + 1 == total_checkpoints and local_shape_index == 0:
			# this is a completed lap
			Globals.lap_completed.emit(body)
			current_checkpoint.set(body, 0)

func _on_race_restarted() -> void:
	current_checkpoint = {}
