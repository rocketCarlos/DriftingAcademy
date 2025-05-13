extends Node2D

# TODO: move all labels and UI logic to its own script
@onready var time_label = $UI/SubViewportContainer/SubViewport/RaceUI/TimeLabel
@onready var speed_label = $UI/SubViewportContainer/SubViewport/RaceUI/Speed

@onready var menu = $UI/SubViewportContainer/SubViewport/MenuUI

@onready var game_subviewport = $Game/SubViewportContainer/SubViewport

var track_time: bool = false
var elapsed_time: float = 0.0

@export var car: PackedScene

var levels = [preload("res://scenes/circuits/circuit_1.tscn")]

func _ready() -> void:
	Globals.lap_completed.connect(_on_lap_completed)
	Globals.first_lap_start.connect(_on_first_lap_start)

func _process(delta: float) -> void:
	if track_time:
		elapsed_time += delta
		time_label.text = str(elapsed_time).pad_decimals(2)
		# round to the closes multiple of 5
		speed_label.text = str(int(round(Globals.car_speeed / 5.0)) * 5)

func _on_lap_completed():
	print(time_label.text)
	elapsed_time = 0

func _on_first_lap_start() -> void:
	track_time = true
	elapsed_time = 0.0

func _on_play_button_button_clicked() -> void:
	var tween = create_tween()
	tween.tween_property(menu, "modulate", Color.TRANSPARENT, 0.2)
	await tween.finished
	menu.hide()
	menu.modulate = Color.WHITE
	
	# TODO: level management system
	var level = levels[0].instantiate()
	var car_instance = car.instantiate()
	level.add_child(car_instance)
	game_subviewport.add_child(level)
	car_instance.position = level.initial_car_position.position
	car_instance.rotation = PI/2
	
