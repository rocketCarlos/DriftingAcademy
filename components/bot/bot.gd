extends CharacterBody2D

var wheels: Array[Node] = [null, null, null, null]
@onready var movement_controller = $MovementController

func _ready() -> void:
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
