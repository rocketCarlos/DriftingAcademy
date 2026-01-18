extends Control
#TODO: show highscore of levels?
@onready var skin_preview = $SkinSelector/SkinPreview
@onready var circuit_preview = $CircuitSelector/CircuitPreview
@onready var gamemode_label = $CircuitSelector/GameModeSelector/Gamemode

var current_skin_index: int = 0
var total_skins: int

var current_circuit_index: int = 0
var total_circuits: int

var current_gamemode_index: int = 0
var total_gamemodes: int

func _ready() -> void:
	total_skins = SkinHolder.skin_names.size()
	skin_preview.texture = SkinHolder.set_skin(SkinHolder.skin_names[current_skin_index]).texture
	total_circuits = CircuitHolder.CIRCUIT_NAME.keys().size()
	circuit_preview.texture = CircuitHolder.set_circuit(CircuitHolder.CIRCUIT_NAME.DRIFTINGS_CRADLE).texture
	Globals.current_gamemode = Globals.GAME_MODE.TIME_TRIAL
	gamemode_label.text = Globals.GAMEMODE_LABELS[Globals.current_gamemode]
	current_gamemode_index = int(Globals.current_gamemode)
	total_gamemodes = Globals.GAME_MODE.keys().size()


#TODO: make a specific scene for selectors to avoid repeating code and node definitions
func _on_back_button_clicked() -> void:
	Router.redirect_to.emit(Router.ROUTE_NAME.MAIN_MENU)


func _on_go_drift_button_clicked() -> void:
	CircuitHolder.load_current_circuit.emit()


func _on_previous_skin_button_clicked() -> void:
	current_skin_index = (current_skin_index + (total_skins-1)) % total_skins
	skin_preview.texture = SkinHolder.set_skin(SkinHolder.skin_names[current_skin_index]).texture


func _on_next_skin_button_clicked() -> void:
	current_skin_index = (current_skin_index + 1) % total_skins
	skin_preview.texture = SkinHolder.set_skin(SkinHolder.skin_names[current_skin_index]).texture


func _on_previous_circuit_button_clicked() -> void:
	current_circuit_index = (current_circuit_index + (total_circuits-1)) % total_circuits
	circuit_preview.texture = CircuitHolder.set_circuit(
		CircuitHolder.CIRCUIT_NAME[CircuitHolder.CIRCUIT_NAME.keys()[current_circuit_index]]
		).texture


func _on_next_circuit_button_clicked() -> void:
	current_circuit_index = (current_circuit_index + 1) % total_circuits
	circuit_preview.texture = CircuitHolder.set_circuit(
		CircuitHolder.CIRCUIT_NAME[CircuitHolder.CIRCUIT_NAME.keys()[current_circuit_index]]
		).texture


func _on_previous_game_mode_button_clicked() -> void:
	current_gamemode_index = (current_gamemode_index + (total_gamemodes-1)) % total_gamemodes
	Globals.current_gamemode = current_gamemode_index as Globals.GAME_MODE
	gamemode_label.text = Globals.GAMEMODE_LABELS[Globals.current_gamemode]


func _on_next_game_mode_button_clicked() -> void:
	current_gamemode_index = (current_gamemode_index + 1) % total_gamemodes
	Globals.current_gamemode = current_gamemode_index as Globals.GAME_MODE
	gamemode_label.text = Globals.GAMEMODE_LABELS[Globals.current_gamemode]
