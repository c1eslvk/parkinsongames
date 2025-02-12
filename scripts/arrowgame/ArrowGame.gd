extends Node2D

enum Directions { UP, DOWN, LEFT, RIGHT }
var MAX_ROUNDS = 5

@onready var screen_border_effect = $ScreenBorderEffect
@onready var screen_border_animation = $ScreenBorderAnimation
@onready var arrow_sprite = $ArrowSprite
@onready var start_message = $StartMessage
@onready var countdown_label = $CountdownLabel
@onready var rules_label = $Rules

var current_direction = Directions.UP
var is_green_arrow = true
var start_time = 0.0
var is_timing = false
var game_started = false
var is_input_enabled = false
var round_counter = 0
var log_entries = []
var log_file_name = ""

# Arrow regions in the sprite sheet
var arrow_regions = {
	"green": {
		Directions.UP: Rect2(42, 16, 11, 14),
		Directions.DOWN: Rect2(55, 16, 11, 14),
		Directions.RIGHT: Rect2(39, 3, 14, 11),
		Directions.LEFT: Rect2(55, 3, 14, 11)
	},
	"red": {
		Directions.UP: Rect2(10, 16, 11, 14),
		Directions.DOWN: Rect2(23, 16, 11, 14),
		Directions.RIGHT: Rect2(7, 3, 14, 11),
		Directions.LEFT: Rect2(23, 3, 14, 11)
	}
}

# Function executed after loading scene
func _ready():
	randomize()
	setup_log_file()
	display_start_prompt()

# Function detecting user input
func _input(event):
	if not game_started:
		if event.is_action_pressed("ui_select"):
			game_started = true
			start_message.visible = false
			rules_label.visible = false
			arrow_sprite.visible = true
			start_countdown()
		elif event.is_action_pressed("ui_cancel"):
			save_log_to_file()
			get_tree().quit()
	else:
		if is_input_enabled:
			if event.is_action_pressed("ui_up"):
				handle_input(Directions.UP)
			elif event.is_action_pressed("ui_down"):
				handle_input(Directions.DOWN)
			elif event.is_action_pressed("ui_left"):
				handle_input(Directions.LEFT)
			elif event.is_action_pressed("ui_right"):
				handle_input(Directions.RIGHT)
			elif event.is_action_pressed("ui_cancel"):
				save_log_to_file()
				get_tree().quit()

# Function generating new direction
func generate_new_direction():
	# counting rounds
	round_counter += 1
	# choosing random direction
	current_direction = randi() % 4
	# choosing random color
	is_green_arrow = randi() % 2 == 0
	var arrow_color = "green" if is_green_arrow else "red"
	# setting sprite region
	var region = arrow_regions[arrow_color][current_direction]
	arrow_sprite.region_rect = region
	# starting timer
	start_time = Time.get_ticks_msec()
	is_timing = true

# Function handling inputs
func handle_input(pressed_direction):
	if is_green_arrow and pressed_direction == current_direction:
		add_correct_point()
		log_entry(get_direction(), "green", "correct")
		animate_border(true)
	elif not is_green_arrow and pressed_direction == get_opposite_direction(current_direction):
		add_correct_point()
		log_entry(get_direction(), "red", "correct")
		animate_border(true)
	else:
		add_incorrect_point()
		log_entry(get_direction(), get_arrow_color(), "incorrect")
		animate_border(false)
	# End game if rached MAX_ROUNDS
	if round_counter >= MAX_ROUNDS:
		end_game()
		return
	# start another round
	start_countdown()

# Function for adding correct point
func add_correct_point():
	Globals.correct_score += 1

# Function for adding incorrect point
func add_incorrect_point():
	Globals.incorrect_score += 1

# Function for getting current direction
func get_direction() -> String:
	match current_direction:
		Directions.UP: return "up"
		Directions.DOWN: return "down"
		Directions.LEFT: return "left"
		Directions.RIGHT: return "right"
	return "unknown"

# Function for getting opposite direction of the given one
func get_opposite_direction(direction):
	match direction:
		Directions.UP: return Directions.DOWN
		Directions.DOWN: return Directions.UP
		Directions.LEFT: return Directions.RIGHT
		Directions.RIGHT: return Directions.LEFT
	return direction

# Function for getting String of current color
func get_arrow_color() -> String:
	return "green" if is_green_arrow else "red"

# Function preparing countdown
func start_countdown() -> void:
	is_input_enabled = false
	is_timing = false
	countdown_label.visible = true
	arrow_sprite.visible = false
	run_countdown()
	
# Function displaying countdown
func run_countdown():
	countdown_label.text = "3"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	countdown_label.visible = false
	arrow_sprite.visible = true
	is_input_enabled = true
	generate_new_direction()

# Function displaying starting message
func display_start_prompt():
	start_message.visible = true
	rules_label.visible = true
	arrow_sprite.visible = false
	countdown_label.visible = false
	
# Function prepating log file
func setup_log_file():
	# preparing string of current date and time
	var current_date = Time.get_datetime_string_from_system(false)
	current_date = current_date.replace(":", "").replace("-", "")
	# preparing name of file "username_YYYYMMDDTHHMM.csv"
	log_file_name = Globals.username + "_" + current_date + ".csv"

# Function for logging one entry
func log_entry(direction: String, color: String, answer: String):
	# calculatin reaction time
	is_timing = false
	var reaction_time = Time.get_ticks_msec() - start_time
	# prepating entry (round number; direction; color; answer; reaction time)
	var entry = str(log_entries.size() + 1) + ";" + direction + ";" + color + ";" + answer + ";" + str(reaction_time)
	log_entries.append(entry)

# Function for saving log file
func save_log_to_file():
	# opening file
	var file_path = "user://arrowgame_data/" + log_file_name
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		# Creating header line
		file.store_line("Number;Direction;Color;Answer;Time")
		# loop for adding entries to log file
		for entry in log_entries:
			file.store_line(entry)
		file.close()
	else:
		print(FileAccess.get_open_error())

# Function activating border animation
func animate_border(is_correct: bool) -> void:
	# setting the border color based on whether the answer was correct
	var target_color = Color(0, 1, 0, 1) if is_correct else Color(1, 0, 0, 1)
	screen_border_effect.color = target_color
	# playing the animation
	screen_border_animation.play("BorderFlash")

# Function ending game after eaching MAX_ROUND
func end_game():
	countdown_label.visible = false
	is_timing = false
	save_log_to_file()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/EndScene.tscn")
