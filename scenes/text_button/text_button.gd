extends Label

@onready var hover_sound = $Hover
@onready var click_sound = $Click

var original_scale = scale
var inside = false

signal button_clicked

func _ready() -> void:
	pivot_offset = size/2

func _on_mouse_entered() -> void:
	inside = true
	var tween = create_tween()
	tween.tween_property(self, 'scale', original_scale*0.85, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	hover_sound.play()

func _on_mouse_exited() -> void:
	inside = false
	var tween = create_tween()
	tween.tween_property(self, 'scale', original_scale, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_released('accelerate') and inside: # if user clicks the button
		click_sound.play()
		button_clicked.emit()
		var tween = create_tween()
		tween.tween_property(self, 'scale', original_scale, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		await tween.finished
		if inside:
			tween = create_tween()
			tween.tween_property(self, 'scale', original_scale*0.85, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
