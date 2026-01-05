extends Node

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

# to guarantee collisions are only counted once per frame
var already_collided_with: Dictionary[Object, Variant]


var body: CharacterBody2D
var input_provider: InputControllerBase
@export var input_provider_path: NodePath

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body = get_parent() as CharacterBody2D
	if not body:
		push_error('Movement controller: Parent not found')
	if not body is CharacterBody2D:
		push_error('Movement Controller: parent is not a CharaterBody') 
	
	input_provider = get_node(input_provider_path)
	if not input_provider:
		push_error('Movement Controller: input provider not found')
		
	if not input_provider is InputControllerBase:
		push_error('Movement Controller: input provider is not an InputControllerBase')
		
	wheels = body.find_children("Wheel?")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	already_collided_with.clear()
	
	var mouse_direction = (input_provider.get_input()-body.global_position).normalized()

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
	var prev_velocity_length = body.velocity.length()
	# the acceleration force input by the player
	force = accel * mouse_direction
	# apply the force to velocity
	body.velocity += force

	adjust_velocity(prev_velocity_length)

	# ---------------------------------------------
	# manage sprite rotation
	# ---------------------------------------------
	#TODO: implement realistic rotation (avoid car doing a 180 in a single frame)
	# 1. Point towards the velocity vector
	var final_rotation = Vector2(0.0, -1.0).angle_to(body.velocity)
	# 2. Adjust rotation to simulate drifting
	var mouse_angle = body.velocity.angle_to(mouse_direction)
	body.rotation = final_rotation + 2*mouse_angle/3

	var collision: KinematicCollision2D = body.move_and_collide(body.velocity*delta)
	if collision and not already_collided_with.has(collision.get_collider()):
		if collision.get_collider().has_method('bounce'):
			var relative_velocity = body.velocity - collision.get_collider_velocity()
			collision.get_collider().bounce(relative_velocity, self)
			#velocity = velocity * (1 - Globals.BOUNCE_FACTOR) SI ESTO, PONER EL ALREADY COLLIDED
			bounce(-relative_velocity, collision.get_collider())
		else: 
			# if energy is not transmitted to another object, bouncing is grater
			var local_bounce_factor = Globals.BOUNCE_FACTOR * 3
			body.velocity = (body.velocity.bounce(collision.get_normal()) * local_bounce_factor)
			
			
#region utility functions
func bounce(origin_vel: Vector2, origin_object: Object) -> void:
	if not already_collided_with.has(origin_object):
		already_collided_with[origin_object] = true
		var prev_vel = body.velocity.length()
		body.velocity += origin_vel * Globals.BOUNCE_FACTOR
		
		adjust_velocity(prev_vel)


func adjust_velocity(prev_velocity_length: float) -> void:
	# Limit speed not to exceed max_speed
	# If exceeding max_speed, use prev_velocity_length to smoothlty
	# reduce velocity until max_speed is reached
	if body.velocity.length() >= max_speed:
		if prev_velocity_length > max_speed:
			# apply smooth deaccel
			body.velocity = body.velocity.normalized() * prev_velocity_length - body.velocity.normalized() * deaccel
			if body.velocity.length() < max_speed:
				# correct if speed is decreased too much
				body.velocity = body.velocity.normalized() * max_speed
		else:
			body.velocity = body.velocity.normalized() * max_speed

func get_wheels_resistance():
	var total = 0
	for wheel in wheels:
		# Tile data of the tile the wheel is in
		var tile_data = Globals.circuit_tileset.get_cell_tile_data(Globals.circuit_tileset.local_to_map(Globals.circuit_tileset.to_local(wheel.global_position)))

		total += tile_data.get_custom_data('terrain_resistance')

	return total
	
#endregion
