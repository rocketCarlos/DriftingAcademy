extends Node2D

@onready var ui_subviewport = $UI/SubViewportContainer/SubViewport
@onready var game_subviewport = $Game/SubViewportContainer/SubViewport

@export var car_scene: PackedScene
@export var bot_scene: PackedScene
@export var pause_scene: PackedScene
# A reference to the player's car. When set to null, it automatically frees the node
var car_instance: CharacterBody2D:
	set(value):
		if value == null:
			car_instance.queue_free()
		car_instance = value

var bots: Array[CharacterBody2D]

# A reference to the currently displayed menu. When set to null, it automatically frees the node
var current_menu: Control = null:
	set(value):
		if value == null:
			current_menu.queue_free()
		current_menu = value

# A reference to the currently displayed circuit. Automatically frees the previous circuit
var circuit_instance: Node2D = null:
	set(value):
		if circuit_instance:
			circuit_instance.queue_free()
		circuit_instance = value


func _ready() -> void:
	Router.redirect_to.connect(_on_redirect_to)
	Router.redirect_to.emit(Router.ROUTE_NAME.MAIN_MENU)
	CircuitHolder.load_current_circuit.connect(_on_load_current_circuit)
	Globals.race_restarted.connect(_on_race_restarted)
	Globals.race_ended.connect(_on_race_ended)
	Globals.race_aborted.connect(_on_race_aborted)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not get_tree().paused and circuit_instance:
		get_tree().paused = true
		var pause_menu = pause_scene.instantiate()
		ui_subviewport.add_child(pause_menu)



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
	AudioService.remove_all_music()
	if CircuitHolder.current_circuit == CircuitHolder.CIRCUIT_NAME.UNDER_CONSTRUCTION:
		return

	Globals.race_scores = {}
	Globals.used_names = []

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
			instantiate_and_initialize_car(circuit_instance, 5)
			game_subviewport.add_child(circuit_instance)
			var semaphore = load("res://components/ui/Semaphore/semaphore.tscn").instantiate()
			semaphore.position = ui_subviewport.size / 2.0
			semaphore.position.y = semaphore.position.y / 3.0
			ui_subviewport.add_child(semaphore)


func _on_race_restarted() -> void:
	car_instance.rotation = circuit_instance.get_initial_rotation()
	car_instance.position = circuit_instance.get_grid_position(-1) # last grid position
	car_instance.velocity = Vector2.ZERO


func _on_race_ended() -> void:
	var time_info = Globals.all_times
	Router.redirect_to.emit(Router.ROUTE_NAME.TIMES_MENU)
	# save game and show results
	if Globals.current_gamemode == Globals.GAME_MODE.TIME_TRIAL:
		current_menu.populate_times(time_info)
		if (
			(
				SaveManager.current_save and
				time_info.reduce(func(accum, number): return accum + number) <
				SaveManager.current_save.get_total_time()
			)
			or
			not SaveManager.current_save
			or
			(SaveManager.current_save and time_info.size() != SaveManager.current_save.lap_times.size())
			):
			SaveManager.save_time_trial(
				SaveManager.TimeTrialCircuitSaveData.new(circuit_instance.name, time_info, GhostRecorder.samples)
			)
	circuit_instance = null


func _on_race_aborted() -> void:
	AudioService.remove_all_music()
	circuit_instance = null


func instantiate_and_initialize_car(circuit: Node, n_bots: int = 0) -> void:
	# instantiate car and set vars
	car_instance = car_scene.instantiate()
	car_instance.rotation = circuit.get_initial_rotation()
	car_instance.set_skin(SkinHolder.get_current_skin())

	car_instance.position = circuit.get_grid_position(n_bots if n_bots > 0 else -1)
	circuit.add_child(car_instance)

	for i in range(n_bots):
		var bot_instance = bot_scene.instantiate()
		bot_instance.rotation = circuit.get_initial_rotation()
		bot_instance.set_skin(SkinHolder.get_current_skin())

		bot_instance.position = circuit.get_grid_position(i)
		circuit.add_child(bot_instance)
