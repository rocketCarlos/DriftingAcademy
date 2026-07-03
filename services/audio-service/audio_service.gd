extends Node

@onready var sfx = $Sfx
@onready var music = $Music

@export_range(0, 125, 1, "suffix:%") var sfx_volume: float = 100
@export_range(0, 125, 1, "suffix:%") var music_volume: float = 100

var already_playing: Array[String] = []

func add_sfx(node: CustomAudioStreamPlayer) -> void:
	node.call_deferred(&"reparent", sfx)

func add_music(node: CustomAudioStreamPlayer, allow_duplicate: bool = false) -> void:
	if allow_duplicate or not node.sound_name in already_playing:
		node.call_deferred(&"reparent", music)
		already_playing.push_back(node.sound_name)
		node.play()
	else:
		node.queue_free()


func remove_music(sound_name: String) -> void:
	if sound_name in already_playing:
		var children = music.get_children()

		for child in children:
			if (child as CustomAudioStreamPlayer).sound_name == sound_name:
				child.queue_free()
				already_playing.pop_at(already_playing.find(sound_name))


func remove_all_music() -> void:
	for child in music.get_children():
		already_playing.pop_at(already_playing.find((child as CustomAudioStreamPlayer).sound_name))
		child.queue_free()
