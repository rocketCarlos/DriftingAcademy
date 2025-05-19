extends Node2D


@onready var race_ui = $UI/SubViewportContainer/SubViewport/RaceUI

@onready var main_menu = $UI/SubViewportContainer/SubViewport/MenuUI
@onready var pre_game_menu = $UI/SubViewportContainer/SubViewport/PreGameMenu
@onready var times_menu = $UI/SubViewportContainer/SubViewport/TimesScreen

@onready var game_subviewport = $Game/SubViewportContainer/SubViewport


@export var car: PackedScene
var car_instance

var levels = [preload("res://scenes/circuits/circuit_1.tscn")]
var current_level: int

func _ready() -> void:
	car_instance = car.instantiate()
	Globals.all_laps_completed.connect(_on_all_laps_completed)

#region signal functions
func _on_play_button_button_clicked() -> void:
	await do_screen_transition(main_menu, pre_game_menu)
	
	pre_game_menu.add_child(car_instance)
	car_instance.position = pre_game_menu.car_position.position
	car_instance.current_state = car_instance.STATE.SKIN_SELECT
	
		
func _on_pre_game_menu_clicked_go_drift(selected_level: int) -> void:
	if selected_level < levels.size():
		current_level = selected_level
		# TODO: level management system
		await do_screen_transition(pre_game_menu, null)
		var level = levels[selected_level].instantiate()
		game_subviewport.add_child(level)
		car_instance.reparent(level)
		car_instance.position = level.initial_car_position.position
		car_instance.current_state = car_instance.STATE.PLAY
		car_instance.rotation = PI/2
	
	
func _on_all_laps_completed(all_times: Array[String], total_time: String) -> void:
	# xd
	times_menu.time_value_1.text = all_times[0]
	times_menu.time_value_2.text = all_times[1]
	times_menu.time_value_3.text = all_times[2]
	times_menu.time_value_4.text = all_times[3]
	times_menu.time_value_5.text = all_times[4]
	times_menu.time_total.text = total_time
	
	do_screen_transition(null, times_menu)
	

func _on_times_screen_clicked_choose_level() -> void:
	await do_screen_transition(times_menu, pre_game_menu)
	#TODO: manage car instances	
	car_instance.position = pre_game_menu.car_position.position
	car_instance.current_state = car_instance.STATE.SKIN_SELECT


func _on_times_screen_clicked_play_again() -> void:
	_on_pre_game_menu_clicked_go_drift(current_level)
	
#endregion
	
#region utility functions
#TODO: improve transitions so that there are no visible "flashes"
func do_screen_transition(prev_menu: Node, new_menu: Node) -> void:
	var tween_prev
	if prev_menu:
		tween_prev = create_tween()
		tween_prev.tween_property(prev_menu, "modulate", Color.TRANSPARENT, 0.2)
	
	var tween_new
	if new_menu:
		tween_new = create_tween()
		new_menu.show()
		if prev_menu:
			prev_menu.modulate = Color.TRANSPARENT
			
		tween_new.tween_property(new_menu, "modulate", Color.WHITE, 0.2)
		
	if prev_menu:
		await tween_prev.finished
	if new_menu:
		await tween_new.finished
		
	if prev_menu:
		prev_menu.hide()
		prev_menu.modulate = Color.WHITE
	
#endregion
