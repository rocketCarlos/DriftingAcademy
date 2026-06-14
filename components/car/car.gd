extends CharacterBody2D

var display_name = "You"

@onready var engine_sound = $Engine
@onready var crash_sound = $Crash
@onready var movement_controller = $MovementController
@onready var camera: Camera2D = $Camera

var last_speed: float
var wheels: Array[Node] = [null, null, null, null]
var can_accelerate: bool = false

#region states
enum STATE {
	PLAY
}

@export var current_state: STATE
#endregion

func _ready() -> void:
	Globals.car = self
	Globals.race_started.connect(_on_race_started)
	wheels = find_children("Wheel?")
	can_accelerate = Globals.current_gamemode == Globals.GAME_MODE.TIME_TRIAL
	camera.make_current()

func _physics_process(_delta: float) -> void:
	var updated_score = Globals.race_scores.get(display_name, Vector2())
	updated_score.y = Globals.circuit.get_position_weight(global_position)
	Globals.race_scores[display_name] = updated_score

	Globals.car_speeed = velocity.length()
	match current_state:
		STATE.PLAY:
			if Input.is_action_pressed("accelerate") and can_accelerate:
				movement_controller.disable_acceleration = false
			else:
				movement_controller.disable_acceleration = true

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

func _on_race_started(_object: Node2D) -> void:
	can_accelerate = true
