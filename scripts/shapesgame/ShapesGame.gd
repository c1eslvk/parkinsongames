extends Node

var shapes = ["Triangle", "Square", "Circle", "Star"]
var colors = ["Red", "Green", "Blue", "Pink"]

var is_input_enabled = false
var start_time = 0.0
var previous_time = 0.0
var game_started = false
var round_counter = 0
var is_countdown = false
var is_timing = false

var log_entries = []
var log_file_name = ""

@onready var screen_border_effect = $ScreenBorderEffect
@onready var screen_border_animation = $ScreenBorderAnimation

@onready var gamemode_label = $UI/GameModeLabel
@onready var random_shape = $RandomShape
@onready var space_to_start_label = $UI/StartMessage
@onready var rules_label = $UI/Rules
@onready var countdown_label = $UI/CountdownLabel
@onready var side_shapes = {
	"top": $TopShape,
	"bottom": $BottomShape,
	"right": $RightShape,
	"left": $LeftShape,
}

var current_gamemode = ""
var current_shape = ""
var current_color = ""

var correct_score = Globals.correct_score
var incorrect_score = Globals.incorrect_score

const MAX_ROUNDS = 5
const SPRITESHEET_PATH = "res://assets/Sprites.png"

# Shapes region in the sprite sheet
var shape_color_regions = {
	"Red Star": Rect2(77, 4, 16, 17),
	"Green Star": Rect2(77, 23, 16, 17),
	"Blue Star": Rect2(77, 42, 16, 17),
	"Pink Star": Rect2(77, 61, 16, 17),
	
	"Red Square": Rect2(95, 5, 16, 16),
	"Green Square": Rect2(95, 24, 16, 16),
	"Blue Square": Rect2(95, 43, 16, 16),
	"Pink Square": Rect2(95, 62, 16, 16),
	
	"Red Circle": Rect2(113, 5, 16, 16),
	"Green Circle": Rect2(113, 24, 16, 16),
	"Blue Circle": Rect2(113, 43, 16, 16),
	"Pink Circle": Rect2(113, 62, 16, 16),
	
	"Red Triangle": Rect2(131, 5, 15, 16),
	"Green Triangle": Rect2(131, 24, 15, 16),
	"Blue Triangle": Rect2(131, 43, 15, 16),
	"Pink Triangle": Rect2(131, 62, 15, 16)
}

# Function executed after loading scene
func _ready() -> void:
	setup_shapes()
	setup_log_file()
	random_shape.visible = false
	countdown_label.visible = false
	display_start_prompt()

# Function for setting up shapes on the sides of the screen
func setup_shapes():
	set_shape_region("Star", "Pink", "right")
	set_shape_region("Triangle", "Red", "top")
	set_shape_region("Circle", "Blue", "bottom")
	set_shape_region("Square", "Green", "left")

# Function for setting up shapes region
func set_shape_region(shape: String, color: String, side: String):
	var key = "%s %s" % [color, shape]
	if not shape_color_regions.has(key):
		return
	# getting regions of sprite
	var region_rect = shape_color_regions[key]
	var side_node = side_shapes[side]
	# assigning sprite for shape
	side_node.region_enabled = true
	side_node.texture = load(SPRITESHEET_PATH)
	side_node.region_rect = region_rect
	# Set metadata for validation
	side_node.set_meta("shape", shape)
	side_node.set_meta("color", color)

# Function prepating log file
func setup_log_file():
	var current_date = Time.get_datetime_string_from_system(false)
	current_date = current_date.replace(":", "").replace("-", "")
	log_file_name = Globals.username + "_" + current_date + ".csv"

# Funcion setting up current round
func setup_game():
	# choosing random shape
	current_shape = shapes[randi() % shapes.size()]
	current_color = colors[randi() % colors.size()]
	var key = "%s %s" % [current_color, current_shape]
	if not shape_color_regions.has(key):
		return
	# assigning sprite to node
	var region_rect = shape_color_regions[key]
	random_shape.region_enabled = true
	random_shape.texture = load(SPRITESHEET_PATH)
	random_shape.region_rect = region_rect
	# starting reaction timer
	start_time = Time.get_ticks_msec()
	# enabling input and increasing round counter
	is_input_enabled = true
	round_counter += 1

# Function handling input
func handle_input(direction):
	if not is_input_enabled:
		return
	is_input_enabled = false
	var target_shape = side_shapes[direction]
	var is_correct = false
	# check answer
	if current_gamemode == "shape":
		is_correct = target_shape.get_meta("shape") == current_shape
	else:
		is_correct = target_shape.get_meta("color") == current_color
	var answer_text = "correct" if is_correct else "not correct"
	# animate border
	if is_correct:
		Globals.correct_score += 1
		animate_border(true)
	else:
		Globals.incorrect_score += 1
		animate_border(false)
	# calculate reaction time
	var reaction_time = Time.get_ticks_msec() - start_time
	previous_time = reaction_time
	# log the entry
	log_entry(target_shape.get_meta("shape"), target_shape.get_meta("color"), answer_text, reaction_time)
	# end game if MAX_ROUNDS reached
	if round_counter >= MAX_ROUNDS:
		end_game()
		return
	# start the next round
	start_countdown()

func _input(event):
	if not game_started:
		if event.is_action_pressed("ui_select"):  # Space bar pressed
			game_started = true
			space_to_start_label.hide()
			rules_label.hide()
			random_shape.visible = true
			start_countdown()
		elif event.is_action_pressed("ui_cancel"):  # Escape button
				save_log_to_file()
				get_tree().quit()
	else:
		if is_input_enabled:
			if event.is_action_pressed("ui_up"):
				handle_input("top")
			elif event.is_action_pressed("ui_down"):
				handle_input("bottom")
			elif event.is_action_pressed("ui_left"):
				handle_input("left")
			elif event.is_action_pressed("ui_right"):
				handle_input("right")
			elif event.is_action_pressed("ui_cancel"):  # Escape button
				save_log_to_file()
				get_tree().quit()

func run_countdown():
	countdown_label.text = "3"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	countdown_label.visible = false
	gamemode_label.visible = false
	is_countdown = false
	random_shape.visible = true
	setup_game()

func start_countdown() -> void:
	if randi() % 2 == 0:
		current_gamemode = "shape"
	else:
		current_gamemode = "color"
	gamemode_label.text = "Group by:\n%s" % current_gamemode.to_upper()
	is_timing = false
	is_countdown = true
	countdown_label.visible = true
	gamemode_label.visible = true
	random_shape.visible = false
	run_countdown()

# Function displaying starting message
func display_start_prompt():
	gamemode_label.text = ""
	space_to_start_label.show()
	rules_label.show()

func save_log_to_file():
	var file_path = "user://shapesgame_data/" + log_file_name
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_line("Number;Shape;Color;Gamemode;Answer;time(ms)")
		for entry in log_entries:
			file.store_line(entry)
		file.close()
		print("Log saved to: " + log_file_name)
	else:
		print(FileAccess.get_open_error())
		print("Failed to save log file")

func log_entry(shape: String, color: String, answer: String, time: int):
	var entry = "%d;%s;%s;%s;%s;%dms" % [log_entries.size() + 1, shape, color, current_gamemode, answer, time]
	log_entries.append(entry)

# Function ending game after eaching MAX_ROUND
func end_game():
	countdown_label.visible = false
	is_timing = false
	save_log_to_file()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/EndScene.tscn")

# Function activating border animation
func animate_border(is_correct: bool) -> void:
	# Set the border color based on whether the answer was correct
	var target_color = Color(0, 1, 0, 1) if is_correct else Color(1, 0, 0, 1)
	screen_border_effect.color = target_color
	# Play the animation
	screen_border_animation.play("BorderFlash")
