extends Control
#TODO: show highscore of levels?
@onready var skin_preview = $SkinSelector/SkinPreview
@onready var circuit_preview = $CircuitSelector/CircuitPreview
@onready var gamemode_label = $CircuitSelector/GameModeSelector/Gamemode
@onready var difficulty_selector = $CircuitSelector/DifficultySelector
@onready var difficulty_label = $CircuitSelector/DifficultySelector/Difficulty

var current_skin_index: int = 0
var total_skins: int

var current_circuit_index: int = 0
var total_circuits: int

var current_gamemode_index: int = 0
var total_gamemodes: int

var current_difficulty_index: int = 0
var total_difficulties: int

func _ready() -> void:
	total_skins = SkinHolder.skin_names.size()
	skin_preview.texture = SkinHolder.set_skin(SkinHolder.skin_names[current_skin_index]).texture

	total_circuits = CircuitHolder.CIRCUIT_NAME.keys().size()
	circuit_preview.texture = CircuitHolder.set_circuit(CircuitHolder.CIRCUIT_NAME.DRIFTINGS_CRADLE).texture

	Globals.current_gamemode = Globals.GAME_MODE.TIME_TRIAL
	gamemode_label.text = Globals.GAMEMODE_LABELS[Globals.current_gamemode]
	current_gamemode_index = int(Globals.current_gamemode)
	total_gamemodes = Globals.GAME_MODE.keys().size()

	Globals.current_difficulty = Globals.DIFFICULTY.ROOKIE
	difficulty_label.text = Globals.DIFFICULTY_LABELS[Globals.current_difficulty]
	current_difficulty_index = int(Globals.current_difficulty)
	total_difficulties = Globals.DIFFICULTY.keys().size()


func _process(_delta: float) -> void:
	if Globals.current_gamemode == Globals.GAME_MODE.VS_MACHINE:
		difficulty_selector.show()
	else:
		difficulty_selector.hide()



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


func _on_previous_game_difficulty_button_clicked() -> void:
	while true:
		current_difficulty_index = (current_difficulty_index + (total_difficulties-1)) % total_difficulties
		Globals.current_difficulty = current_difficulty_index as Globals.DIFFICULTY
		difficulty_label.text = Globals.DIFFICULTY_LABELS[Globals.current_difficulty]

		# avoid UNSET
		if Globals.current_difficulty != Globals.DIFFICULTY.UNSET:
			break



func _on_next_game_difficulty_button_clicked() -> void:
	while true:
		current_difficulty_index = (current_difficulty_index + 1) % total_difficulties
		Globals.current_difficulty = current_difficulty_index as Globals.DIFFICULTY
		difficulty_label.text = Globals.DIFFICULTY_LABELS[Globals.current_difficulty]

		# avoid UNSET
		if Globals.current_difficulty != Globals.DIFFICULTY.UNSET:
			break
