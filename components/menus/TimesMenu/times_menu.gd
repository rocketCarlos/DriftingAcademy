extends Control

@export var times_row_scene: PackedScene
@export var ranking_row_scene: PackedScene
@onready var times_row_preview = $TimesContainer/TimesRow
@onready var new_record_label = $NewRecord
@onready var ranking_container = $Ranking

func _ready() -> void:
	AudioService.remove_all_music()
	times_row_preview.queue_free()

	if Globals.current_gamemode == Globals.GAME_MODE.VS_MACHINE:
		for node in get_tree().get_nodes_in_group(&"TimeTrial"):
			node.queue_free()

		var p: int = 1

		var node_names = Globals.race_scores.keys()
		node_names.sort_custom(func(a, b):
			var score_a = Globals.race_scores[a]
			var score_b = Globals.race_scores[b]
			return score_a.x > score_b.x if score_a.x != score_b.x else score_a.y < score_b.y
		)
		for name in node_names:
			var row = ranking_row_scene.instantiate()
			row.get_node("Position").text = str(p)
			row.get_node("Name").text = str(name)
			ranking_container.add_child(row)
			p += 1

	else:
		for node in get_tree().get_nodes_in_group(&"VsCpu"):
			node.queue_free()

		new_record_label.scale = Vector2(0.8, 0.8)
		while true:
			var tween = create_tween()
			tween.tween_property(new_record_label, "scale", Vector2(1.3, 1.3), 0.5)
			tween.tween_property(new_record_label, "scale", Vector2(0.8, 0.8), 0.5)
			await tween.finished


func _process(delta: float) -> void:
	if Globals.current_gamemode == Globals.GAME_MODE.TIME_TRIAL:
		new_record_label.pivot_offset = new_record_label.size / 2.0


func populate_times(times: Array[float]) -> void:
	var times_container = get_node("TimesContainer")

	var title_row = times_row_scene.instantiate()
	title_row.get_node("LapNumber").text = "LAP"
	title_row.get_node("Value").text = "TIME"
	title_row.get_node("Value2").text = "BEST"
	times_container.add_child(title_row)

	var i: int = 1
	var acc: float = 0
	for record in times:
		var row = times_row_scene.instantiate()
		row.get_node("LapNumber").text = str(i) + "."
		row.get_node("Value").text = str(record)
		if SaveManager.current_save and i-1 < SaveManager.current_save.lap_times.size():
			row.get_node("Value2").text = str(SaveManager.current_save.lap_times[i-1])
		else:
			row.get_node("Value2").text = str(record)

		times_container.add_child(row)
		acc += record
		i += 1

	var total_time = times_row_scene.instantiate()
	total_time.get_node("LapNumber").text = "Total time:"
	total_time.get_node("Value").text = str(acc)
	if SaveManager.current_save:
		total_time.get_node("Value2").text = str(SaveManager.current_save.get_total_time())
	else:
		total_time.get_node("Value2").text = str(acc)
	times_container.add_child(total_time)

	if (
		(
			(not SaveManager.current_save)
			or
			(SaveManager.current_save.get_total_time() > acc)
			or
			(SaveManager.current_save.lap_times.size() != times.size())
		)
		and Globals.current_gamemode == Globals.GAME_MODE.TIME_TRIAL
	):
		new_record_label.show()
	else:
		new_record_label.hide()


func _on_play_again_button_clicked() -> void:
	CircuitHolder.load_current_circuit.emit()


func _on_choose_level_button_clicked() -> void:
	Router.redirect_to.emit(Router.ROUTE_NAME.SKIN_CIRCUIT_SELECTOR)
