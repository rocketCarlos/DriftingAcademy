extends CharacterBody2D

@onready var engine_sound = $Engine
@onready var crash_sound = $Crash
@onready var movement_controller = $MovementController

var last_speed: float
var wheels: Array[Node] = [null, null, null, null]

#region states
enum STATE {
	PLAY
}

@export var current_state: STATE
#endregion

func _ready() -> void:
	Globals.car = self
	wheels = find_children("Wheel?")

func _physics_process(_delta: float) -> void:
	Globals.car_speeed = velocity.length()
	match current_state:
		STATE.PLAY:
			if Input.is_action_pressed("accelerate"):
				movement_controller.disable_acceleration = false
			else:
				movement_controller.disable_acceleration = true
				if velocity.length() > 0:
					velocity -= velocity.normalized() * movement_controller.deaccel
					# Prevent overshooting and stop when speed is very low
					if velocity.length() < 10.0:  # Threshold for stopping
						velocity = Vector2(0, 0)

func _process(_delta: float) -> void:
	engine_sound.pitch_scale = 1 + inverse_lerp(0, movement_controller.SPEED_ROAD, velocity.length()) * 1.5

	if last_speed - velocity.length() > 75.0:
		crash_sound.play()

	last_speed = velocity.length()

#region utility functions

"""
Sets the skin and wheel colliders based on the provided skin
"""
func set_skin(new_skin: Node) -> void:
	# set wheel relative positions
	for i in range(wheels.size()):
		get_node("Wheel"+str(i+1)).position = new_skin.get_node("Wheel"+str(i+1)).position
	# set collision shape
	get_node("CollisionShape2D").shape = new_skin.find_child("CollisionShape2D").shape
	# set skin
	get_node("Skin").texture = new_skin.texture


#endregion
