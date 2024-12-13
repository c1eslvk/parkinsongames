extends Control

@onready var name_input = $NameInput

func handle_username_submission():
	var username = name_input.text.strip_edges()
	if username == "":
		username = "Unkown"
	Globals.username = username
	if (Globals.chosen_game == Globals.Games.ARROW_GAME):
		get_tree().change_scene_to_file("res://scenes/arrowgame/ArrowGame.tscn")
	elif (Globals.chosen_game == Globals.Games.SHAPES_GAME):
		get_tree().change_scene_to_file("res://scenes/shapesgame/ShapesGame.tscn")
	elif (Globals.chosen_game == Globals.Games.MATHEMATICAL_MAZE):
		get_tree().change_scene_to_file("res://scenes/mathematicalmaze/MathematicalMaze.tscn")


func _on_submit_button_pressed() -> void:
	handle_username_submission()


func _input(event):
	if event.is_action_pressed("ui_accept"):
		handle_username_submission()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GameMenu.tscn")
