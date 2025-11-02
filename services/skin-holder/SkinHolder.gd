extends Node2D

"""
Steps to add a skin:
	1. Add a new Sprite2D node as a child of SkinSelector and attach the sprite of the new skin
	2. Add 4 Node2D to the Sprite2D node, name them Wheel[1-4] and place them on the wheels' locations
	3. Add a CollisionShape2D to the Sprite2D node (keep the default "CollisionShape2D" name for it)
		and create a shape for it to represent the skin's hitbox
"""

var skin_names: Array[String] = []
var current_skin: String

func _ready() -> void:
	# check if skin holder is correctly configured and compute skin names
	var children = get_children()
	for child in children:
		if child.is_class('Sprite2D'):
			skin_names.push_back(child.name)
			if child.get_child_count() != 5: # 4 wheels and a collision shape
				push_warning('Unexpected amount of children for node ', child.name)
		else:
			push_warning('Found a non Sprite2D node: ', child.name)

"""
Sets as current and returns the Sprite2D node corresponding to the provided skin name. Returns null
if the provided skin name does not exist
"""
func set_skin(skin_name: String) -> Sprite2D:
	var skin = get_node_or_null(skin_name)
	if skin == null:
		push_error('No skin found with name ', skin_name)
	else:
		current_skin = skin_name

	return skin

"""
Returns an array with the name of available skins
"""
func get_skin_names() -> Array:
	return skin_names

"""
Gets the current skin
"""
func get_current_skin() -> Node:
	return find_child(current_skin)
