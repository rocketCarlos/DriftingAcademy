extends Node2D

#region scene nodes
@onready var body = $Body
#endregion

#region variables
const MAX_SPEED = 300.0

const MAX_ACCEL: float = 1000.0
const MIN_ACCEL: float = 500.0
var accel: float = MIN_ACCEL

const MAX_DEACCEL: float = 1000.0
const MIN_DEACCEL: float = 100.0
var deaccel: float = MIN_DEACCEL
# measures how slippery the surface is. 
# The higher, the more inertia there is
# max is 1.0
var slippery_factor: float = 0.98
#endregion
'''
IDEAS/TODOS: add dynamic acceleration so that it feels different accelerating from stopped
than the acceleration used in drifting
'''
func _physics_process(delta: float) -> void:
	var mouse_position = get_global_mouse_position()
	var mouse_direction = (mouse_position - body.global_position).normalized()
	var angle = Vector2(0.0, -1.0).angle_to(mouse_direction)

	# -----------------------------------------
	# manage movement
	# -----------------------------------------
	var force =  Vector2(0.0, 0.0)
	if Input.is_action_pressed("accelerate"):
		#TODO: implement dynamic acceleration
		
		# the acceleration force input by the player
		force = accel * mouse_direction * delta
		# apply the force to velocity
		body.velocity += force
		
		# Limit speed not to exceed MAX_SPEED
		if body.velocity.length() >= MAX_SPEED:
			body.velocity = body.velocity.normalized() * MAX_SPEED
			
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
			body.velocity -= body.velocity.normalized() * deaccel * delta
			# Prevent overshooting and stop when speed is very low
			if body.velocity.length() < 10.0:  # Threshold for stopping
				body.velocity = Vector2(0, 0)
				
	body.move_and_slide()
