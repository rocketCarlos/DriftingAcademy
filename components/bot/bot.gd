extends CharacterBody2D
var display_name = "Bot"
var wheels: Array[Node] = [null, null, null, null]
@onready var movement_controller = $MovementController
@onready var name_label = $Label

func _ready() -> void:
	Globals.race_started.connect(_on_race_started)
	wheels = find_children("Wheel?")
	movement_controller.disable_acceleration = true
	while true:
		display_name = Globals.bot_names.pick_random()
		if display_name not in Globals.used_names:
			Globals.used_names.append(display_name)
			break
	name_label.text = display_name

func set_skin(new_skin: Node) -> void:
	# set wheel relative positions
	for i in range(wheels.size()):
		get_node("Wheel"+str(i+1)).position = new_skin.get_node("Wheel"+str(i+1)).position
	# set collision shape
	get_node("CollisionShape2D").shape = new_skin.find_child("CollisionShape2D").shape
	# set skin
	get_node("Skin").texture = new_skin.texture


func _physics_process(_delta: float) -> void:
	var updated_score = Globals.race_scores.get(display_name, Vector2())
	updated_score.y = Globals.circuit.get_position_weight(global_position)
	Globals.race_scores[display_name] = updated_score


func _process(delta: float) -> void:
	name_label.rotation = -rotation
	name_label.global_position = global_position + Vector2(-26.0, -21.0)


func _on_race_started(_object: Node2D) -> void:
	movement_controller.disable_acceleration = false
