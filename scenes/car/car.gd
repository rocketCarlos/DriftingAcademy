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
	# ---------------------------------------------
	# manage sprite rotation
	# ---------------------------------------------
	var mouse_position = get_global_mouse_position()
	var direction = (mouse_position - body.global_position).normalized()
	var angle = Vector2(0.0, -1.0).angle_to(direction)
	
	body.rotation = angle
	# -----------------------------------------
	# manage movement and camera
	# -----------------------------------------
	var force =  Vector2(0.0, 0.0)
	if Input.is_action_pressed("accelerate"):
		# the acceleration force input by the player
		force = accel * direction * delta
		# apply the force to velocity
		body.velocity += force
		# decide based on the slippery factor how important is the new force's
		# direction in the final velocity. To do so, split the velocity's length
		# into proportional parts for each direction (the original and the new)
		'''body.velocity = (
			(body.velocity.length()*slippery_factor) * 
			body.velocity.normalized() + 
			(body.velocity.length()*(1.0-slippery_factor)) * 
			force.normalized()
		)'''
		
		# Limit speed not to exceed MAX_SPEED
		if body.velocity.length() >= MAX_SPEED:
			body.velocity = body.velocity.normalized() * MAX_SPEED
	else:
		if body.velocity.length() > 0:
			body.velocity -= body.velocity.normalized() * deaccel * delta
			# Prevent overshooting and stop when speed is very low
			if body.velocity.length() < 10.0:  # Threshold for stopping
				body.velocity = Vector2(0, 0)
				
	body.move_and_slide()
