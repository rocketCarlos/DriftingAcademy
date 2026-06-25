extends Control

@onready var master_slider: HSlider = $MarginContainer/VBoxContainer/Master/CenterContainer/MasterSlider
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/SFX/CenterContainer/SFXSlider

func _ready() -> void:
	master_slider.value = Settings.master_volume
	sfx_slider.value = Settings.sfx_volume


func _on_master_slider_value_changed(value: float) -> void:
	Settings.master_volume = value


func _on_sfx_slider_value_changed(value: float) -> void:
	Settings.sfx_volume = value
