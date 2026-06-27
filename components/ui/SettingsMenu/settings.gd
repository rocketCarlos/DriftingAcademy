extends Control

@onready var master_slider: HSlider = $MarginContainer/VBoxContainer/Master/MasterSlider
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/Specifics/SFX/CenterContainer/SFXSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/Specifics/Music/CenterContainer/MusicSlider

func _ready() -> void:
	master_slider.value = Settings.master_volume
	sfx_slider.value = Settings.sfx_volume
	music_slider.value = Settings.music_volume


func _on_master_slider_value_changed(value: float) -> void:
	Settings.master_volume = value


func _on_sfx_slider_value_changed(value: float) -> void:
	Settings.sfx_volume = value


func _on_music_slider_value_changed(value: float) -> void:
	Settings.music_volume = value
