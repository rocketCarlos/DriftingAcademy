extends Control

@export var credits_scene: PackedScene

func _on_play_button_clicked() -> void:
	Router.redirect_to.emit(Router.ROUTE_NAME.SKIN_CIRCUIT_SELECTOR)

func _on_credits_button_clicked() -> void:
	add_child(credits_scene.instantiate())


func _on_settings_button_clicked() -> void:
	add_child(Globals.settings_scene.instantiate())
