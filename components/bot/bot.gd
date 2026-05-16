extends CharacterBody2D
var display_name = "Bot"
var wheels: Array[Node] = [null, null, null, null]
@onready var movement_controller = $MovementController

func _ready() -> void:
	Globals.race_started.connect(_on_race_started)
	wheels = find_children("Wheel?")
	movement_controller.disable_acceleration = true

func set_skin(new_skin: Node) -> void:
	# set wheel relative positions
	for i in range(wheels.size()):
		get_node("Wheel"+str(i+1)).position = new_skin.get_node("Wheel"+str(i+1)).position
	# set collision shape
	get_node("CollisionShape2D").shape = new_skin.find_child("CollisionShape2D").shape
	# set skin
	get_node("Skin").texture = new_skin.texture


func _physics_process(_delta: float) -> void:
	var updated_score = Globals.race_scores.get(self, Vector2())
	updated_score.y = Globals.circuit.get_position_weight(global_position)
	Globals.race_scores[self] = updated_score

func _on_race_started(_object: Node2D) -> void:
	movement_controller.disable_acceleration = false
