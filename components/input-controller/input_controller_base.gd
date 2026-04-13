class_name InputControllerBase
extends Node

var input: Vector2
var parent: CharacterBody2D

func _ready() -> void:
	parent = get_parent() as CharacterBody2D

	if not parent:
		push_error('Input Base Controller: parent not found')

	if not parent is Node2D:
		push_error('Input Base Controller: parent is not a CharacterBody2D object')

func get_input() -> Vector2:
	return input
