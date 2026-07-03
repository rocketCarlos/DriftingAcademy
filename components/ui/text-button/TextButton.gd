@tool
extends Label

"""
Default text button with animations and sfx for hover and click. Emits a signal when clicked.
Accepts overrides for sounds and label settings through export variables
"""

@onready var ChildLabel = $Label
@onready var SoundClick: CustomAudioStreamPlayer = $Click
@onready var SoundHover: CustomAudioStreamPlayer = $Hover

signal button_clicked

@export var click: AudioStream = preload("res://assets/sfx/ui/Selección.ogg")
@export var hover: AudioStream = preload("res://assets/sfx/ui/Hover.ogg")
@export var custom_label_settings: LabelSettings = preload("res://assets/label-settings/default-font.tres"):
	set(value):
		custom_label_settings = value
		label_settings = custom_label_settings
		ChildLabel.label_settings = custom_label_settings

var original_scale = scale
var inside = false

func _ready() -> void:
	ChildLabel.text = text
	ChildLabel.pivot_offset = ChildLabel.size / 2
	self_modulate = Color.TRANSPARENT

	SoundClick.stream = click
	SoundHover.stream = hover
	label_settings = custom_label_settings
	ChildLabel.label_settings = custom_label_settings


func _process(_delta: float) -> void:
	ChildLabel.text = text
	ChildLabel.pivot_offset = ChildLabel.size / 2

func _on_mouse_entered() -> void:
	inside = true
	SoundHover.play()
	var tween = create_tween()
	tween.tween_property(ChildLabel, 'scale', original_scale*0.85, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	inside = false
	var tween = create_tween()
	tween.tween_property(ChildLabel, 'scale', original_scale, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_released('click') and inside:
		button_clicked.emit()
		SoundClick.play()
		var tween = create_tween()
		tween.tween_property(ChildLabel, 'scale', original_scale, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		await tween.finished
		if inside:
			tween = create_tween()
			tween.tween_property(ChildLabel, 'scale', original_scale*0.85, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
