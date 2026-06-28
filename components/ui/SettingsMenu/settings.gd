extends Control

@onready var master_slider: HSlider = $MarginContainer/VBoxContainer/Master/MasterSlider
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/Specifics/SFX/CenterContainer/SFXSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/Specifics/Music/CenterContainer/MusicSlider

@onready var master_volume_indicator: Label = $MarginContainer/VBoxContainer/Master/Label/Label
@onready var music_volume_indicator: Label = $MarginContainer/VBoxContainer/Specifics/Music/Label/Label
@onready var sfx_volume_indicator: Label = $MarginContainer/VBoxContainer/Specifics/SFX/Label/Label


func _ready() -> void:
	master_slider.value = Settings.master_volume
	sfx_slider.value = Settings.sfx_volume
	music_slider.value = Settings.music_volume


func _process(_delta: float) -> void:
	master_volume_indicator.text = str(int(Settings.master_volume * 100))
	music_volume_indicator.text = str(int(Settings.music_volume * 100))
	sfx_volume_indicator.text = str(int(Settings.sfx_volume * 100))

func _on_master_slider_value_changed(value: float) -> void:
	Settings.master_volume = value


func _on_sfx_slider_value_changed(value: float) -> void:
	Settings.sfx_volume = value


func _on_music_slider_value_changed(value: float) -> void:
	Settings.music_volume = value


func _on_back_button_button_clicked() -> void:
	queue_free()
