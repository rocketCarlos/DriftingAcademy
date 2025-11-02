extends Control


func _on_play_button_clicked() -> void:
	Router.redirect_to.emit(Router.ROUTE_NAME.SKIN_CIRCUIT_SELECTOR)

func _on_credits_button_clicked() -> void:
	pass
