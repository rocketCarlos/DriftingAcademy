extends Control

#TODO: load highscore of current level. Maybe also show it in level selector?

@export var times_row_scene: PackedScene
@onready var times_row_preview = $TimesContainer/TimesRow

func _ready() -> void:
	times_row_preview.queue_free()

func populate_times(times: Array[float]) -> void:
	var times_container = get_node("TimesContainer")
	var i: int = 1
	var acc: float = 0
	for record in times:
		var row = times_row_scene.instantiate()
		row.get_node("LapNumber").text = str(i) + "."
		row.get_node("Value").text = str(record)
		times_container.add_child(row)
		acc += record
		i += 1

	var total_time = times_row_scene.instantiate()
	total_time.get_node("LapNumber").text = "Total time:"
	total_time.get_node("Value").text = str(acc)
	times_container.add_child(total_time)


func _on_play_again_button_clicked() -> void:
	CircuitHolder.load_current_circuit.emit()


func _on_choose_level_button_clicked() -> void:
	Router.redirect_to.emit(Router.ROUTE_NAME.SKIN_CIRCUIT_SELECTOR)
