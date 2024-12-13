extends Node

@onready var correct_score_label = $CorrectScoreLabel
@onready var incorrect_score_label = $IncorrectScoreLabel
@onready var restart_button = $RestartButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	correct_score_label.text = "Correct: " + str(Globals.correct_score)
	incorrect_score_label.text = "Incorrect: " + str(Globals.incorrect_score)
	
func _on_restart_button_pressed():
	Globals.correct_score = 0
	Globals.incorrect_score = 0
	
	if (Globals.chosen_game == Globals.Games.ARROW_GAME):
		get_tree().change_scene_to_file("res://scenes/arrowgame/ArrowGame.tscn")
	elif (Globals.chosen_game == Globals.Games.SHAPES_GAME):
		get_tree().change_scene_to_file("res://scenes/shapesgame/ShapesGame.tscn")
	elif (Globals.chosen_game == Globals.Games.MATHEMATICAL_MAZE):
		get_tree().change_scene_to_file("res://scenes/mathematicalmaze/MathematicalMaze.tscn")


func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
