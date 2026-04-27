extends Node2D

@onready var ui_subviewport = $UI/SubViewportContainer/SubViewport
@onready var game_subviewport = $Game/SubViewportContainer/SubViewport

@export var car_scene: PackedScene
# A reference to the player's car. When set to null, it automatically frees the node
var car_instance: CharacterBody2D:
	set(value):
		if value == null:
			car_instance.queue_free()
		car_instance = value

# A reference to the currently displayed menu. When set to null, it automatically frees the node
var current_menu: Control = null:
	set(value):
		if value == null:
			current_menu.queue_free()
		current_menu = value

# A reference to the currently displayed circuit. When set to null, it automatically frees the node
var circuit_instance: Node2D = null:
	set(value):
		if value == null:
			circuit_instance.queue_free()
		circuit_instance = value


func _ready() -> void:
	Router.redirect_to.connect(_on_redirect_to)
	Router.redirect_to.emit(Router.ROUTE_NAME.MAIN_MENU)
	CircuitHolder.load_current_circuit.connect(_on_load_current_circuit)
	Globals.race_restarted.connect(_on_race_restarted)
	Globals.race_ended.connect(_on_race_ended)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		Globals.race_restarted.emit()



func _on_redirect_to(route: Router.ROUTE_NAME) -> void:
	var new_menu = Router.ROUTES.get(route)

	if new_menu:
		if current_menu:
			current_menu.queue_free()

		var new_menu_instance = new_menu.instantiate()
		ui_subviewport.add_child(new_menu_instance)
		current_menu = new_menu_instance
	else:
		push_error('Tried to instance null menu. Provided route was ', route)


func _on_load_current_circuit() -> void:
	if CircuitHolder.current_circuit == CircuitHolder.CIRCUIT_NAME.UNDER_CONSTRUCTION:
		return

	Router.redirect_to.emit(Router.ROUTE_NAME.RACE_HUD)

	# instantiate selected circuit
	circuit_instance = CircuitHolder.get_and_initialize_current_circuit()

	match Globals.current_gamemode:
		Globals.GAME_MODE.TIME_TRIAL:
			SaveManager.load_time_trial(circuit_instance.name)
			# intialize car and instantiate it in the current circuit
			instantiate_and_initialize_car(circuit_instance)
			game_subviewport.add_child(circuit_instance)
		Globals.GAME_MODE.VS_MACHINE:
			instantiate_and_initialize_car(circuit_instance)
			game_subviewport.add_child(circuit_instance)


func _on_race_restarted() -> void:
	car_instance.rotation = circuit_instance.get_initial_rotation()
	car_instance.position = circuit_instance.get_grid_position(-1) # last grid position
	car_instance.velocity = Vector2.ZERO


func _on_race_ended() -> void:
	# get time from current menu because the menu while racing is the race_hud
	# TODO: move time saving to other scene so that it is independent from current menu
	var time_info = current_menu.all_times
	Router.redirect_to.emit(Router.ROUTE_NAME.TIMES_MENU) # current menu is now times_menu
	current_menu.populate_times(time_info)
	# save game
	if (
		(SaveManager.current_save and
		time_info.reduce(func(accum, number): return accum + number) <
		SaveManager.current_save.get_total_time())
		or
		not SaveManager.current_save
		or
		(SaveManager.current_save and time_info.size() != SaveManager.current_save.lap_times.size())
		):
		SaveManager.save_time_trial(
			SaveManager.TimeTrialCircuitSaveData.new(circuit_instance.name, time_info, GhostRecorder.samples)
		)
	circuit_instance = null



func instantiate_and_initialize_car(circuit: Node) -> void:
	# instantiate car and set vars
	car_instance = car_scene.instantiate()
	car_instance.rotation = circuit.get_initial_rotation()
	car_instance.set_skin(SkinHolder.get_current_skin())

	car_instance.position = circuit.get_grid_position(-1) # last grid position

	if Globals.current_gamemode == Globals.GAME_MODE.VS_MACHINE:
		circuit.instantiate_bots() # TODO: this!!

	circuit.add_child(car_instance)
