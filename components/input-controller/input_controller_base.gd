@abstract
class_name InputControllerBase
extends Node

var input: Vector2
var parent: CanvasItem

func _ready() -> void:
	parent = get_parent() as CanvasItem
	
	if not parent: 
		push_error('Input Base Controller: parent not found')
	
	if not parent is CanvasItem:
		push_error('Input Base Controller: parent is not a Canvas Item')

func get_input() -> Vector2:
	return input
