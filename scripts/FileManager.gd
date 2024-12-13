extends Control

func _ready():
	var dir_path
	if (Globals.chosen_game == Globals.Games.ARROW_GAME):
		dir_path = "user://arrowgame_data/"
	elif (Globals.chosen_game == Globals.Games.SHAPES_GAME):
		dir_path = "user://shapesgame_data/"
	elif (Globals.chosen_game == Globals.Games.MATHEMATICAL_MAZE):
		dir_path = "user://mathematicalmaze_data/"
	var dir = DirAccess.open(dir_path)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var container = $ScrollContainer/VBoxContainer

		while file_name != "":
			if not dir.current_is_dir():
				var user_info = parse_file_name(file_name)
				if user_info:
					var button = Button.new()
					button.text = user_info["formatted"]
					button.pressed.connect(Callable(_on_file_button_pressed).bind(file_name))
					container.add_child(button)
			file_name = dir.get_next()

		dir.list_dir_end()

func parse_file_name(file_name: String):
	# Remove the file extension
	var base_name = file_name.get_basename()
	
	# Expected file name format: Username_YYYYMMDDTHHMMSS
	var parts = base_name.split("_")
	if parts.size() != 2:
		return null

	var username = parts[0]
	var datetime_str = parts[1].split("T")
	if datetime_str.size() != 2:
		return null

	var date = datetime_str[0]
	var time = datetime_str[1]

	return {
		"username": username,
		"date": date.insert(4, "-").insert(7, "-"),  # Format YYYY-MM-DD
		"time": time.insert(2, ":").insert(5, ":"), # Format HH:MM:SS
		"formatted": "%s - %s %s" % [username, date.insert(4, "-").insert(7, "-"), time.insert(2, ":").insert(5, ":")]
	}

func _on_file_button_pressed(file_name: String) -> void:
	print("File clicked:", file_name)
	Globals.chosen_file_to_display = file_name
	get_tree().change_scene_to_file("res://scenes/arrowgame/DataDisplay.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GameMenu.tscn")


func _on_open_dir_button_pressed() -> void:
	var dir_path
	if (Globals.chosen_game == Globals.Games.ARROW_GAME):
		dir_path = "user://arrowgame_data/"
	elif (Globals.chosen_game == Globals.Games.SHAPES_GAME):
		dir_path = "user://shapesgame_data/"
	elif (Globals.chosen_game == Globals.Games.MATHEMATICAL_MAZE):
		dir_path = "user://mathematicalmaze_data/"
	var absolute_path = ProjectSettings.globalize_path(dir_path)
	OS.shell_show_in_file_manager(absolute_path, true)
