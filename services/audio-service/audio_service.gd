extends Node

@onready var sfx = $Sfx
@onready var music = $Music

@export_range(0, 125, 1, "suffix:%") var sfx_volume: float = 100
@export_range(0, 125, 1, "suffix:%") var music_volume: float = 100

func add_sfx(node: Node) -> void:
	node.call_deferred(&"reparent", sfx)

func add_music(node: Node) -> void:
	node.call_deferred(&"reparent", music)
