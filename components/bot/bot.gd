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

# to guarantee collisions are only counted once per frame
var already_collided_with: Dictionary[Object, Variant]
#endregion

#region states
enum STATE {
	PLAY
}

@export var current_state: STATE
#endregion

var current_point = 0
var input_tween: Tween = null
@export var debug: bool = false
func _ready() -> void:
	wheels = find_children("Wheel?")
	points = get_tree().get_nodes_in_group("BotPoints")
	current_point = 0
	virtual_input = points[current_point].position

	if not debug:
		$VirtualInputDebug.hide()

func _physics_process(_delta: float) -> void:
	already_collided_with.clear()
	
	if debug:
		$VirtualInputDebug.global_position = virtual_input


	if points.size() == 0:
		points = get_tree().get_nodes_in_group("BotPoints")
		return

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

	adjust_velocity(prev_velocity_length)

	# ---------------------------------------------
	# manage sprite rotation
	# ---------------------------------------------
	#TODO: implement realistic rotation (avoid car doing a 180 in a single frame)
	# 1. Point towards the velocity vector
	var final_rotation = Vector2(0.0, -1.0).angle_to(velocity)
	# 2. Adjust rotation to simulate drifting
	var mouse_angle = velocity.angle_to(mouse_direction)
	rotation = final_rotation + 2*mouse_angle/3

	var collision: KinematicCollision2D = move_and_collide(velocity*_delta)
	if collision and not already_collided_with.has(collision.get_collider()):
		if collision.get_collider().has_method('bounce'):
			var relative_velocity = velocity - collision.get_collider_velocity()
			collision.get_collider().bounce(relative_velocity, self)
			#velocity = velocity * (1 - Globals.BOUNCE_FACTOR) SI ESTO, PONER EL ALREADY COLLIDED
			bounce(-relative_velocity, collision.get_collider())
		else: 
			# if energy is not transmitted to another object, bouncing is grater
			var local_bounce_factor = Globals.BOUNCE_FACTOR * 3
			velocity = (velocity.bounce(collision.get_normal()) * local_bounce_factor)


func bounce(origin_vel: Vector2, origin_object: Object) -> void:
	if not already_collided_with.has(origin_object):
		already_collided_with[origin_object] = true
		var prev_vel = velocity.length()
		velocity += origin_vel * Globals.BOUNCE_FACTOR
		
		adjust_velocity(prev_vel)


func adjust_velocity(prev_velocity_length: float) -> void:
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
	if input_tween:
		input_tween.kill()

	input_tween = create_tween()

	var new_virtual_position = points[current_point].position
	var interpolation_time: float
	var min_interpolation: float = 0.2
	var max_interpolation: float = 1

	interpolation_time = (
		clampf(
			lerpf(
				min_interpolation,
				max_interpolation,
				inverse_lerp(0.0, 1500.0, virtual_input.distance_to(new_virtual_position))
			),
			min_interpolation,
			max_interpolation
		)
	)

	(input_tween
		.tween_property(self, "virtual_input", new_virtual_position, interpolation_time)
		.set_trans(Tween.TRANS_LINEAR)
		.set_ease(Tween.EASE_OUT)
	)
