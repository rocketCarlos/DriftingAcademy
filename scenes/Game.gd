extends Node2D


@onready var race_ui = $UI/SubViewportContainer/SubViewport/RaceUI

@onready var main_menu = $UI/SubViewportContainer/SubViewport/MenuUI
@onready var pre_game_menu = $UI/SubViewportContainer/SubViewport/PreGameMenu

@onready var game_subviewport = $Game/SubViewportContainer/SubViewport

@export var car: PackedScene
var car_instance

var levels = [preload("res://scenes/circuits/circuit_1.tscn")]

func _ready() -> void:
	car_instance = car.instantiate()

#region signal functions
func _on_play_button_button_clicked() -> void:
	await do_screen_transition(main_menu, pre_game_menu)
	
	pre_game_menu.add_child(car_instance)
	car_instance.position = pre_game_menu.car_position.position
	car_instance.current_state = car_instance.STATE.SKIN_SELECT
	
		
func _on_pre_game_menu_clicked_go_drift(selected_level: int) -> void:
	if selected_level < levels.size():
		# TODO: level management system
		await do_screen_transition(pre_game_menu, null)
		var level = levels[selected_level].instantiate()
		game_subviewport.add_child(level)
		car_instance.reparent(level)
		car_instance.position = level.initial_car_position.position
		car_instance.current_state = car_instance.STATE.PLAY
		car_instance.rotation = PI/2
	
#endregion
	
#region utility functions
#TODO: improve transitions so that there are no visible "flashes"
func do_screen_transition(prev_menu: Node, new_menu: Node) -> void:
	var tween_prev = create_tween()
	tween_prev.tween_property(prev_menu, "modulate", Color.TRANSPARENT, 0.2)
	
	var tween_new
	if new_menu:
		tween_new = create_tween()
		new_menu.show()
		prev_menu.modulate = Color.TRANSPARENT
		tween_new.tween_property(new_menu, "modulate", Color.WHITE, 0.2)
	
	await tween_prev.finished
	if new_menu:
		await tween_new.finished
	
	prev_menu.hide()
	prev_menu.modulate = Color.WHITE
#endregion
