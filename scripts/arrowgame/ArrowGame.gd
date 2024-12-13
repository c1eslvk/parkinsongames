extends Node2D

enum Directions { UP, DOWN, LEFT, RIGHT }

var NUM_OF_ROUNDS = 5

@onready var arrow_sprite = $ArrowSprite
@onready var start_message = $StartMessage
@onready var countdown_label = $CountdownLabel
var current_direction = Directions.UP
var is_green_arrow = true
var start_time = 0.0
var is_timing = false
var game_started = false
var is_countdown = false

var log_entries = []
var log_file_name = ""

# Define arrow regions in the sprite sheet
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

func _ready():
	randomize()
	start_message.visible = true
	arrow_sprite.visible = false
	countdown_label.visible = false
	setup_log_file()

func generate_new_direction():
	current_direction = randi() % 4
	is_green_arrow = randi() % 2 == 0
	
	var arrow_color = "green" if is_green_arrow else "red"
	var region = arrow_regions[arrow_color][current_direction]
	arrow_sprite.region_rect = region
	
	start_time = Time.get_ticks_msec()
	is_timing = true

func _process(delta):
	if not game_started:
		if Input.is_action_just_pressed("ui_accept"):
			game_started = true
			start_message.visible = false
			arrow_sprite.visible = true
			start_countdown()
			generate_new_direction()
		return

	if is_countdown:
		# Ignore input during countdown
		return

	if is_timing:
		var current_time = Time.get_ticks_msec()
		var elapsed_time = current_time - start_time

	var input_pressed = false

	if is_green_arrow:
		if Input.is_action_just_pressed("ui_up") and current_direction == Directions.UP:
			add_correct_point()
			log_entry("up", "green", "correct")
			input_pressed = true
		elif Input.is_action_just_pressed("ui_down") and current_direction == Directions.DOWN:
			add_correct_point()
			log_entry("down", "green", "correct")
			input_pressed = true
		elif Input.is_action_just_pressed("ui_left") and current_direction == Directions.LEFT:
			add_correct_point()
			log_entry("left", "green", "correct")
			input_pressed = true
		elif Input.is_action_just_pressed("ui_right") and current_direction == Directions.RIGHT:
			add_correct_point()
			log_entry("right", "green", "correct")
			input_pressed = true
		else:
			input_pressed = check_incorrect_input()
	else:
		if Input.is_action_just_pressed("ui_up") and current_direction == Directions.DOWN:
			add_correct_point()
			log_entry("up", "red", "correct")
			input_pressed = true
		elif Input.is_action_just_pressed("ui_down") and current_direction == Directions.UP:
			add_correct_point()
			log_entry("down", "red", "correct")
			input_pressed = true
		elif Input.is_action_just_pressed("ui_left") and current_direction == Directions.RIGHT:
			add_correct_point()
			log_entry("left", "red", "correct")
			input_pressed = true
		elif Input.is_action_just_pressed("ui_right") and current_direction == Directions.LEFT:
			add_correct_point()
			log_entry("right", "red", "correct")
			input_pressed = true
		else:
			input_pressed = check_incorrect_input()

	if input_pressed:
		start_countdown()

	if (Globals.correct_score + Globals.incorrect_score) == NUM_OF_ROUNDS:
		save_log_to_file()
		get_tree().change_scene_to_file("res://scenes/EndScene.tscn")

	if Input.is_action_just_pressed("ui_cancel"):
		save_log_to_file()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		
func add_correct_point():
	Globals.correct_score += 1
	record_reaction_time()

func add_incorrect_point():
	Globals.incorrect_score += 1
	record_reaction_time()

func check_incorrect_input() -> bool:
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		add_incorrect_point()
		log_entry(get_direction(), get_arrow_color(), "incorrect")
		return true
	return false

func record_reaction_time():
	var reaction_time = Time.get_ticks_msec() - start_time
	is_timing = false

func run_countdown():
	countdown_label.text = "3"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	countdown_label.visible = false
	is_countdown = false
	arrow_sprite.visible = true
	generate_new_direction()

func start_countdown() -> void:
	is_timing = false
	is_countdown = true
	countdown_label.visible = true
	arrow_sprite.visible = false
	
	run_countdown()

func setup_log_file():
	var current_date = Time.get_datetime_string_from_system(false)
	current_date = current_date.replace(":", "").replace("-", "")
	log_file_name = Globals.username + "_" + current_date + ".txt"

func save_log_to_file():
	var file_path = "user://arrowgame_data/" + log_file_name
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_line("No.|direction|color|answer|time")
		for entry in log_entries:
			file.store_line(entry)
		file.close()
		print("Log saved to: " + log_file_name)
	else:
		print(FileAccess.get_open_error())
		print("Failed to save log file")
	
func log_entry(direction: String, color: String, answer: String):
	var reaction_time = Time.get_ticks_msec() - start_time
	var entry = str(log_entries.size() + 1) + "|" + direction + "|" + color + "|" + answer + "|" + str(reaction_time)
	log_entries.append(entry)

func get_direction() -> String:
	if current_direction == Directions.UP:
		return "up"
	if current_direction == Directions.DOWN:
		return "down"
	if current_direction == Directions.LEFT:
		return "left"
	if current_direction == Directions.RIGHT:
		return "right"
	return "unknown"

func get_arrow_color() -> String:
	return "green" if is_green_arrow else "red"
