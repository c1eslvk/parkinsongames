extends Node

var correct_answer = 0
var total_rounds = 0
var is_input_enabled = false

var log_file_name = ""
var log_entries = []
var round_start_time = 0
var last_round_time = 0 

@onready var doors = [
	$DoorsUp,
	$DoorsBottom,
	$DoorsLeft,
	$DoorsRight
]
@onready var equation_label = $Equation
@onready var correct_label = $CorrectLabel
@onready var incorrect_label = $IncorrectLabel
@onready var time_label = $TimeLabel  # Time display label

func _ready() -> void:
	setup_log_file()
	generate_round()

func _process(delta: float) -> void:
	var current_time = Time.get_ticks_msec() - round_start_time
	time_label.text = "Time: %dms (Previous: %dms)" % [current_time, last_round_time]

func setup_log_file():
	var current_date = Time.get_datetime_string_from_system(false)
	current_date = current_date.replace(":", "").replace("-", "")
	log_file_name = Globals.username + "_" + current_date + ".txt"	

func generate_round():
	if total_rounds >= 50:
		end_game()
		return

	total_rounds += 1
	print("round: ", total_rounds)

	round_start_time = Time.get_ticks_msec()
	time_label.text = "Time: 0ms (Previous: %dms)" % last_round_time
	
	var num1 = randi() % 10 + 1
	print("num1: ", num1)
	var num2 = randi() % 10 + 1
	print("num2: ", num2)
	var is_addition = randi() % 2 == 0
	print("is addition:", is_addition)

	correct_answer = num1 + num2 if is_addition else num1 - num2
	equation_label.text = str(num1) + (" + " if is_addition else " - ") + str(num2)

	var answers = [correct_answer]
	while answers.size() < 4:
		var random_answer = randi() % 20 - 5
		print("random_answer: ", random_answer)
		if random_answer not in answers and random_answer >= 0:
			answers.append(random_answer)
	answers.shuffle()

	for i in range(doors.size()):
		var answer_label = doors[i].get_node_or_null("Answer")
		if answer_label:
			answer_label.text = str(answers[i])
		else:
			print("error. missing answer node in door")
			push_error("Missing 'Answer' node in door: " + str(i))

func check_answer(selected_index):
	var answer_label = doors[selected_index].get_node_or_null("Answer")
	if answer_label:
		var selected_answer = int(answer_label.text)
		var time_taken = Time.get_ticks_msec() - round_start_time  # Calculate time taken
		
		# Update the time label
		last_round_time = time_taken  # Store the time for this round as the "previous" time
		time_label.text = "Time: %dms (Previous: %dms)" % [time_taken, last_round_time]

		# Update scores
		if selected_answer == correct_answer:
			Globals.correct_score += 1
			correct_label.text = "Correct: " + str(Globals.correct_score)
		else:
			Globals.incorrect_score += 1
			incorrect_label.text = "Incorrect: " + str(Globals.incorrect_score)
		
		# Log the entry
		log_entry(equation_label.text, str(selected_answer), time_taken)
	else:
		push_error("Invalid door selected or missing 'Answer' label!")
	
	generate_round()

func _input(event):
	if event.is_action_pressed("ui_up"):
		print("pressed up")
		check_answer(0)
	elif event.is_action_pressed("ui_down"):
		print("pressed down")
		check_answer(1)
	elif event.is_action_pressed("ui_left"):
		print("pressed left")
		check_answer(2)
	elif event.is_action_pressed("ui_right"):
		print("pressed right")
		check_answer(3)
	elif event.is_action_pressed("ui_cancel"):
		save_log_to_file()
		get_tree().quit()

func end_game():
	# Save logs to file before ending the game
	save_log_to_file()
	
	# Transition to the end scene
	var end_scene_path = "res://scenes/EndScene.tscn"
	if ResourceLoader.exists(end_scene_path):
		get_tree().change_scene_to_file(end_scene_path)
	else:
		push_error("End scene file not found: " + end_scene_path)  # Debug message for missing end scene

func save_log_to_file():
	var file_path = "user://mathematicalmaze_data/" + log_file_name
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_line("No.|Equation|Answer|Time(ms)")  # Header for log file
		for entry in log_entries:
			file.store_line(entry)
		file.close()
		print("Log saved to: " + file_path)
	else:
		print(FileAccess.get_open_error())
		print("Failed to save log file")

func log_entry(equation: String, answer: String, time: int):
	var entry = "%d|%s|%s|%dms" % [log_entries.size() + 1, equation, answer, time]
	log_entries.append(entry)
