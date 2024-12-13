extends Control

@onready var table = $ScrollContainer/VBoxContainer

# To store the graph data points
var x_values = []
var y_values = []

func _ready():
	if Globals.chosen_file_to_display:
		load_and_display_data(Globals.chosen_file_to_display)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func load_and_display_data(file_name: String):
	var file_path = "user://arrowgame_data/" + file_name
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		# Read and display data
		var table_data = []
		var line = file.get_line()  # Skip the header
		line = file.get_line()
		while line:
			var row = line.split("|")
			if row.size() == 5:
				table_data.append(row)
			line = file.get_line()
		file.close()
		
		# Display data in table
		display_data_table(table_data)
		
		# Prepare graph data
		prepare_graph_data(table_data)
		queue_redraw()  # Trigger a redraw of the graph

func display_data_table(data: Array):
	for row in data:
		var label = Label.new()
		label.text = "%s | %s | %s | %s | %s" % [row[0], row[1], row[2], row[3], row[4]]
		table.add_child(label)

func prepare_graph_data(data: Array):
	# Prepare x and y values from the data for plotting
	x_values.clear()
	y_values.clear()
	for row in data:
		if row[0].is_valid_int() and row[4].is_valid_int():
			x_values.append(row[0].to_int())  # No.
			y_values.append(row[4].to_int()) # Time

# Draw the graph
func _draw():
	if x_values.size() <= 1:
		return  # Not enough data to plot

	# Scale the graph (adjust as needed)
	var scale_x = 50
	var scale_y = 50
	var offset_x = 100  # Left margin
	var offset_y = 100  # Top margin

	var prev_point = Vector2(offset_x + x_values[0] * scale_x, offset_y + y_values[0] * scale_y)

	for i in range(1, x_values.size()):
		var current_point = Vector2(offset_x + x_values[i] * scale_x, offset_y + y_values[i] * scale_y)
		
		# Draw line between the points
		draw_line(prev_point, current_point, Color(1, 0, 0), 2)  # Red color and line width 2
		
		prev_point = current_point


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/FileManager.tscn")
