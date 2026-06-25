extends Node

var master_volume: float = 100.0:
	set(new_value):
		master_volume = clampf(new_value, 0.0, 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))

var sfx_volume: float = 100.0:
	set(new_value):
		sfx_volume = clampf(new_value, 0.0, 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFXs"), linear_to_db(sfx_volume))
