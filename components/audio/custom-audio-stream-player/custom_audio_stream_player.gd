extends AudioStreamPlayer
class_name CustomAudioStreamPlayer

@export_enum("SFX", "Music") var audio_type: String = "SFX"
@export var sound_name: String

func _ready() -> void:
	if audio_type == "SFX":
		AudioService.add_sfx(self)
	elif audio_type == "Music":
		AudioService.add_music(self)
