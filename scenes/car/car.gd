extends CharacterBody2D

#region variables
var max_speed: float
const SPEED_ROAD: float = 300.0
const SPEED_GRASS: float = 150.0
const SPEED_GRAVEL: float = 100.0

var accel: float
const ACCEL_ROAD: float = 500.0
const ACCEL_GRASS: float = 250.0
const ACCEL_GRAVEL: float = 100.0

var deaccel: float
const DEACCEL_ROAD: float = 100.0
const DEACCEL_GRASS: float = 200.0
const DEACCEL_GRAVEL: float = 400.0

#endregion


func _physics_process(delta: float) -> void:
	var mouse_position = get_global_mouse_position()
	var mouse_direction = (mouse_position - global_position).normalized()
	var angle = Vector2(0.0, -1.0).angle_to(mouse_direction)
	
	# Tile data of the tile the car is in
	var tile_data = Globals.circuit_tileset.get_cell_tile_data(Globals.circuit_tileset.local_to_map(Globals.circuit_tileset.to_local(global_position)))
	
	var tile_name = tile_data.get_custom_data('tile_name')
	match tile_name:
		#TODO: each tile has a "speed score" depending on how much road there is.
		# speed is calculated based on that score
		#TODO: manage speed based on the specific tile each car's wheel is in!
		'road', 'curb':
			max_speed = SPEED_ROAD
			accel = ACCEL_ROAD
			deaccel = DEACCEL_ROAD
		'grass', 'gravel_grass': 
			max_speed = SPEED_GRASS
			accel = ACCEL_GRASS
			deaccel = DEACCEL_GRASS
		'gravel':
			max_speed = SPEED_GRAVEL
			accel = ACCEL_GRAVEL
			deaccel = DEACCEL_GRAVEL
		_:
			max_speed = SPEED_ROAD
			accel = ACCEL_ROAD
			deaccel = DEACCEL_ROAD
			
	# -----------------------------------------
	# manage movement
	# -----------------------------------------
	var force =  Vector2(0.0, 0.0)
	if Input.is_action_pressed("accelerate"):
		# the acceleration force input by the player
		force = accel * mouse_direction * delta
		# apply the force to velocity
		velocity += force
		
		# Limit speed not to exceed max_speed
		if velocity.length() >= max_speed:
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
		
	else:
		if velocity.length() > 0:
			velocity -= velocity.normalized() * deaccel * delta
			# Prevent overshooting and stop when speed is very low
			if velocity.length() < 10.0:  # Threshold for stopping
				velocity = Vector2(0, 0)
				
	move_and_slide()
