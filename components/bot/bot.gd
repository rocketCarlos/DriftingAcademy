extends CharacterBody2D

#region variables
var max_speed: float
const SPEED_ROAD: float = 300.0
const SPEED_CURBS: float = 200.0
const SPEED_GRASS: float = 150.0
const SPEED_GRAVEL: float = 100.0

var accel: float
const ACCEL_ROAD: float = 8.5
const ACCEL_CURBS: float = 6.8
const ACCEL_GRASS: float = 4.25
const ACCEL_GRAVEL: float = 1.7

var deaccel: float
const DEACCEL_ROAD: float = 4.675
const DEACCEL_CURBS: float = 5.1
const DEACCEL_GRASS: float = 5.95
const DEACCEL_GRAVEL: float = 6.8

var wheels: Array[Node] = [null, null, null, null]

var last_speed: float

var virtual_input: Vector2
var points: Array
#endregion

#region states
enum STATE {
	PLAY
}

@export var current_state: STATE
#endregion

var current_point = 0
func _ready() -> void:
	wheels = find_children("Wheel?")
	points = get_tree().get_nodes_in_group("BotPoints")

func _physics_process(_delta: float) -> void:
	if points.size() == 0:
		points = get_tree().get_nodes_in_group("BotPoints")
		return

	virtual_input = points[current_point].position
	var mouse_direction = (virtual_input-global_position).normalized()
	var angle = Vector2(0.0, -1.0).angle_to(mouse_direction)

	# -----------------------------------------
	# manage terrain resistance
	# -----------------------------------------
	var total_resistance = get_wheels_resistance()

	if total_resistance <= 3:
		max_speed = SPEED_ROAD
		accel = ACCEL_ROAD
		deaccel = DEACCEL_ROAD
	elif total_resistance <= 6:
		max_speed = SPEED_CURBS
		accel = ACCEL_CURBS
		deaccel = DEACCEL_CURBS
	elif total_resistance <= 8:
		max_speed = SPEED_GRASS
		accel = ACCEL_GRASS
		deaccel = DEACCEL_GRASS
	else:
		max_speed = SPEED_GRAVEL
		accel = ACCEL_GRAVEL
		deaccel = DEACCEL_GRAVEL

	# -----------------------------------------
	# manage movement
	# -----------------------------------------
	var force =  Vector2(0.0, 0.0)
	# if Input.is_action_pressed("accelerate"):
	var prev_velocity_length = velocity.length()
	# the acceleration force input by the player
	force = accel * mouse_direction
	# apply the force to velocity
	velocity += force

	# Limit speed not to exceed max_speed
	# If exceeding max_speed, use prev_velocity_length to smoothlty
	# reduce velocity until max_speed is reached
	if velocity.length() >= max_speed:
		if prev_velocity_length > max_speed:
			# apply smooth deaccel
			velocity = velocity.normalized() * prev_velocity_length - velocity.normalized() * deaccel
			if velocity.length() < max_speed:
				# correct if speed is decreased too much
				velocity = velocity.normalized() * max_speed
		else:
			velocity = velocity.normalized() * max_speed

	# ---------------------------------------------
	# manage sprite rotation
	# ---------------------------------------------
	#TODO: implement realistic rotation (avoid car doing a 180 in a single frame)
	# 1. Point towards the velocity vector
	var final_rotation = Vector2(0.0, -1.0).angle_to(velocity)
	# 2. Adjust rotation to simulate drifting
	var mouse_angle = velocity.angle_to(mouse_direction)
	rotation = final_rotation + 2*mouse_angle/3

	#else:
	#	if velocity.length() > 0:
	#		velocity -= velocity.normalized() * deaccel
	#		# Prevent overshooting and stop when speed is very low
	#		if velocity.length() < 10.0:  # Threshold for stopping
	#			velocity = Vector2(0, 0)

	move_and_slide()

#region utility functions
func get_wheels_resistance():
	var total = 0
	for wheel in wheels:
		# Tile data of the tile the wheel is in
		var tile_data = Globals.circuit_tileset.get_cell_tile_data(Globals.circuit_tileset.local_to_map(Globals.circuit_tileset.to_local(wheel.global_position)))

		total += tile_data.get_custom_data('terrain_resistance')

	return total

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


func _on_points_detector_area_entered(area: Area2D) -> void:
	current_point = (current_point + 1) % points.size()
