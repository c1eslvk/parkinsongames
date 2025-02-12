extends Control

@onready var load_button = $BackButton

var times_index

func _ready():
	var file_name = Globals.chosen_file_to_display
	var dir_path
	if (Globals.chosen_game == Globals.Games.ARROW_GAME):
		dir_path = "user://arrowgame_data/"
		times_index = 5
	elif (Globals.chosen_game == Globals.Games.SHAPES_GAME):
		dir_path = "user://shapesgame_data/"
		times_index = 6
	elif (Globals.chosen_game == Globals.Games.MATHEMATICAL_MAZE):
		dir_path = "user://mathematicalmaze_data/"
		times_index = 4
	var dir = DirAccess.open(dir_path)
	var file_path = dir_path + file_name
	load_and_display_graph(file_path)

func load_and_display_graph(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return
	var data = []
	var first_line = true
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			if first_line:
				first_line = false
				continue
			data.append(line.split(";"))
	file.close()
	
	if data.is_empty():
		return
	display_graph(data)
	
func display_graph(data: Array):
	var graph_points = []
	# getting reaction times
	var times = []
	for row in data:
		if row.size() >= times_index:
			times.append(row[times_index - 1].to_int())
	if times.is_empty():
		return
	
	# setting up boundaries of the graph and adding points
	var max_y = -INF
	for i in range(times.size()):
		var x = i
		var y = times[i]
		if y > max_y:
			max_y = y
		graph_points.append(Vector2(x, y))
	
	# configuring and displaying graph
	var graph = $Graph2D
	graph.x_max = times.size()
	graph.y_max = max_y + 100
	var plot = graph.add_plot_item("", Color.GREEN, 1.0)

	for point in graph_points:
		plot.add_point(point)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/FileManager.tscn")
