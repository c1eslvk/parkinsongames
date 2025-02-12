extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# clear all global variables
	Globals.username = ""
	Globals.correct_score = 0
	Globals.incorrect_score = 0
	Globals.chosen_file_to_display = ""
	Globals.chosen_game = null
	ensure_directories()

# create directories for log files for each game
func ensure_directories():
	var dir = DirAccess.open("user://")
	dir.make_dir("arrowgame_data")
	dir.make_dir("shapesgame_data")
	dir.make_dir("mathematicalmaze_data")

# Arrow Game button signal
func _on_arrow_game_button_pressed() -> void:
	Globals.chosen_game = Globals.Games.ARROW_GAME
	get_tree().change_scene_to_file("res://scenes/GameMenu.tscn")

# Shapes Game button signal
func _on_shapes_game_button_pressed() -> void:
	Globals.chosen_game = Globals.Games.SHAPES_GAME
	get_tree().change_scene_to_file("res://scenes/GameMenu.tscn")

# Mathematical Game button signal
func _on_mathematical_maze_button_pressed() -> void:
	Globals.chosen_game = Globals.Games.MATHEMATICAL_MAZE
	get_tree().change_scene_to_file("res://scenes/GameMenu.tscn")
	
# Exit button signal
func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# quit game
		get_tree().quit()
