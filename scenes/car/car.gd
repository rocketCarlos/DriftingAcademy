extends CharacterBody2D

@onready var hitbox_blue = $BlueCar
@onready var hitbox_f1 = $F1Car
@onready var hitbox_pointy = $PointyCar
@onready var hitbox_chev = $ChevCar

@onready var skin_blue = $Skins/BlueCar
@onready var skin_f1 = $Skins/F1Car
@onready var skin_pointy = $Skins/PointyCar
@onready var skin_chev = $Skins/ChevCar

@onready var camera = $Camera

@onready var engine_sound = $Engine
@onready var crash_sound = $Crash

enum SKIN {
	BLUE,
	F1,
	POINTY,
	CHEV
}

#region variables
var max_speed: float
const SPEED_ROAD: float = 300.0
const SPEED_CURBS: float = 200.0
const SPEED_GRASS: float = 150.0
const SPEED_GRAVEL: float = 100.0

var accel: float
const ACCEL_ROAD: float = 500.0
const ACCEL_CURBS: float = 400.0
const ACCEL_GRASS: float = 250.0
const ACCEL_GRAVEL: float = 100.0

var deaccel: float
const DEACCEL_ROAD: float = 275.0
const DEACCEL_CURBS: float = 300.0
const DEACCEL_GRASS: float = 350.0
const DEACCEL_GRAVEL: float = 400.0

var wheels: Array = [null, null, null, null]

var last_speed: float

var current_skin: SKIN
#endregion

#region states
enum STATE {
	PLAY
}

@export var current_state: STATE
#endregion

func _ready() -> void:
	update_skin(SKIN.BLUE)
	

func _physics_process(delta: float) -> void:
	match current_state:
		STATE.PLAY:	
			var mouse_position = get_global_mouse_position()
			var mouse_direction = (mouse_position - global_position).normalized()
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
			if Input.is_action_pressed("accelerate"):
				var prev_velocity_length = velocity.length()
				# the acceleration force input by the player
				force = accel * mouse_direction * delta
				# apply the force to velocity
				velocity += force
				
				# Limit speed not to exceed max_speed
				# If exceeding max_speed, use prev_velocity_length to smoothlty
				# reduce velocity until max_speed is reached
				if velocity.length() >= max_speed:
					if prev_velocity_length > max_speed:
						# apply smooth deaccel
						velocity = velocity.normalized() * prev_velocity_length - velocity.normalized() * deaccel * delta
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
				
			else:
				if velocity.length() > 0:
					velocity -= velocity.normalized() * deaccel * delta
					# Prevent overshooting and stop when speed is very low
					if velocity.length() < 10.0:  # Threshold for stopping
						velocity = Vector2(0, 0)
						
			Globals.car_speeed = velocity.length()
			move_and_slide()
		
func _process(delta: float) -> void:
	engine_sound.pitch_scale = 1 + inverse_lerp(0, SPEED_ROAD, velocity.length()) * 1.5
	
	if last_speed - velocity.length() > 75.0:
		crash_sound.play()
	
	last_speed = velocity.length()

#region utility functions
func get_wheels_resistance():
	var total = 0
	for wheel in wheels:
		# Tile data of the tile the wheel is in
		var tile_data = Globals.circuit_tileset.get_cell_tile_data(Globals.circuit_tileset.local_to_map(Globals.circuit_tileset.to_local(wheel.global_position)))
		
		total += tile_data.get_custom_data('terrain_resistance')
		
	return total
	
func update_skin(new_skin: SKIN) -> void:
	match current_skin:
		SKIN.BLUE:
			hitbox_blue.disabled = true
			skin_blue.hide()
		SKIN.F1:
			hitbox_f1.disabled = true
			skin_f1.hide()
		SKIN.POINTY:
			hitbox_pointy.disabled = true
			skin_pointy.hide()
		SKIN.CHEV:
			hitbox_chev.disabled = true
			skin_chev.hide()
	
	current_skin = new_skin
	
	var node_path = ''
	match new_skin:
		SKIN.BLUE:
			node_path = 'Skins/BlueCar/Wheel'
			hitbox_blue.disabled = false
			skin_blue.show()
		SKIN.F1:
			node_path = 'Skins/F1Car/Wheel'
			hitbox_f1.disabled = false
			skin_f1.show()
		SKIN.POINTY:
			node_path = 'Skins/PointyCar/Wheel'
			hitbox_pointy.disabled = false
			skin_pointy.show()
		SKIN.CHEV:
			node_path = 'Skins/ChevCar/Wheel'
			hitbox_chev.disabled = false
			skin_chev.show()
			
	for i in range(4):
		wheels[i] = get_node(node_path+str(i+1))

#endregion
