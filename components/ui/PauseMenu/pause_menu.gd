extends Control

func _on_resume_button_clicked() -> void:
	get_tree().paused = false
	queue_free()

func _on_restart_button_clicked() -> void:
	CircuitHolder.load_current_circuit.emit()
	get_tree().paused = false
	queue_free()

func _on_choose_level_button_clicked() -> void:
	Router.redirect_to.emit(Router.ROUTE_NAME.SKIN_CIRCUIT_SELECTOR)
	get_tree().paused = false
	queue_free()
