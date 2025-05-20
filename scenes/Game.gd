extends Node2D


@onready var race_ui = $UI/SubViewportContainer/SubViewport/RaceUI

@onready var main_menu = $UI/SubViewportContainer/SubViewport/MenuUI
@onready var pre_game_menu = $UI/SubViewportContainer/SubViewport/PreGameMenu
@onready var times_menu = $UI/SubViewportContainer/SubViewport/TimesScreen
@onready var credits_menu = $UI/SubViewportContainer/SubViewport/Credits

@onready var game_subviewport = $Game/SubViewportContainer/SubViewport

var levels = [preload("res://scenes/circuits/circuit_1.tscn")]
var current_level: int

func _ready() -> void:
	Globals.all_laps_completed.connect(_on_all_laps_completed)

#region signal functions
func _on_play_button_button_clicked() -> void:
	await do_screen_transition(main_menu, pre_game_menu)
	
		
func _on_pre_game_menu_clicked_go_drift(selected_level: int) -> void:
	if selected_level < levels.size():
		current_level = selected_level
		# TODO: level management system
		await do_screen_transition(pre_game_menu, null)
		var level = levels[selected_level].instantiate()
		game_subviewport.add_child(level)
	
	
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


func _on_times_screen_clicked_play_again() -> void:
	await do_screen_transition(times_menu, null)
	var level = levels[current_level].instantiate()
	game_subviewport.add_child(level)
	
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
	

func _on_menu_ui_clicked_credits() -> void:
	do_screen_transition(main_menu, credits_menu)
	

func _on_credits_clicked_go_back() -> void:
	do_screen_transition(credits_menu, main_menu)
	
	
func _on_pre_game_menu_clicked_go_back() -> void:
	do_screen_transition(pre_game_menu, main_menu)
	
#endregion
