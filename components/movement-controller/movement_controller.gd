extends Node
class_name MovementController

var disable_acceleration: bool = false

#region velocity related
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
#endregion

var wheels: Array[Node] = [null, null, null, null]

#region physics related
const BOUNCE_FACTOR: float = 0.65 # 0 = inelastic collision, 1 = perfect elastic collision
const MAX_BOUNCE: float = 300.0
const MIN_BOUNCE: float = 25.0

var already_collided_this_frame: Dictionary[MovementController, bool]
#endregion

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
	if not disable_acceleration:
		body.velocity = calculate_next_velocity(mouse_direction)

		# ---------------------------------------------
		# manage sprite rotation
		# ---------------------------------------------
		#TODO: implement realistic rotation (avoid car doing a 180 in a single frame)
		# 1. Point towards the velocity vector
		var final_rotation = Vector2(0.0, -1.0).angle_to(body.velocity)
		# 2. Adjust rotation to simulate drifting
		var mouse_angle = body.velocity.angle_to(mouse_direction)
		body.rotation = final_rotation + 2*mouse_angle/3
	else:
		if body.velocity.length() > 0:
			body.velocity -= body.velocity.normalized() * deaccel
			# Prevent overshooting and stop when speed is very low
			if body.velocity.length() < 10.0:  # Threshold for stopping
				body.velocity = Vector2(0, 0)

	var collision: KinematicCollision2D = body.move_and_collide(body.velocity*delta)
	if collision:
		var normal_collision = collision.get_normal().normalized()
		var relative_velocity = body.velocity * 2.0 * BOUNCE_FACTOR
		if collision.get_collider() is CharacterBody2D and collision.get_collider().get_node('MovementController'):
			var other_body = collision.get_collider().get_node('MovementController')
			if not already_collided_this_frame.get(other_body, false):
				relative_velocity = body.velocity - other_body.body.velocity
				other_body.make_collision(-normal_collision, other_body.body.velocity - body.velocity)
				other_body.already_collided_this_frame[self] = true

		make_collision(normal_collision, relative_velocity)

	already_collided_this_frame.clear()



#region utility functions
func make_collision(normal_collision: Vector2, relative_velocity: Vector2) -> void:
	# physics formula for collisions between two puntual particles with equal mass
	# disregarding friction and depending on elasticity
	var impulse = normal_collision.x * relative_velocity.x + normal_collision.y * relative_velocity.y

	var final_velocity = Vector2(
		body.velocity.x - impulse * normal_collision.x,
		body.velocity.y - impulse * normal_collision.y
	)

	body.velocity = final_velocity


func calculate_next_velocity(mouse_direction: Vector2) -> Vector2:
	var next_velocity: Vector2

	var force =  Vector2(0.0, 0.0)
	# if Input.is_action_pressed("accelerate"):
	var prev_velocity_length = body.velocity.length()
	# the acceleration force input by the player
	force = accel * mouse_direction
	# apply the force to velocity
	next_velocity = body.velocity + force


	return get_adjusted_velocity(next_velocity, prev_velocity_length)

func get_adjusted_velocity(unadjusted_velocity: Vector2, prev_velocity_length: float) -> Vector2:
	var adjusted_velocity: Vector2 = unadjusted_velocity
	# Limit speed not to exceed max_speed
	# If exceeding max_speed, use prev_velocity_length to smoothlty
	# reduce velocity until max_speed is reached
	if unadjusted_velocity.length() >= max_speed:
		if prev_velocity_length > max_speed:
			# apply smooth deaccel
			adjusted_velocity = unadjusted_velocity.normalized() * prev_velocity_length - unadjusted_velocity.normalized() * deaccel
			if adjusted_velocity.length() < max_speed:
				# correct if speed is decreased too much
				adjusted_velocity = adjusted_velocity.normalized() * max_speed
		else:
			adjusted_velocity = unadjusted_velocity.normalized() * max_speed

	return adjusted_velocity

func get_wheels_resistance():
	var total = 0
	for wheel in wheels:
		# Tile data of the tile the wheel is in
		var tile_data: TileData = Globals.circuit_tileset.get_cell_tile_data(Globals.circuit_tileset.local_to_map(Globals.circuit_tileset.to_local(wheel.global_position)))

		total += tile_data.get_custom_data('terrain_resistance')

	return total

#endregion

func simulate_move(input: Vector2, delta) -> Vector2:
	var simulated_velocity = calculate_next_velocity(input)

	var collision = body.move_and_collide(simulated_velocity * delta, true)

	return collision.get_travel() if collision else simulated_velocity * delta
