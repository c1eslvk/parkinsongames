extends Node

var correct_answer = 0
var total_rounds = 0
var is_input_enabled = false
var current_door_index = -1  # Index of the door being approached
var MAX_ROUNDS = 5

var log_file_name = ""
var log_entries = []
var round_start_time = 0

var game_started = false

@onready var screen_border_effect = $ScreenBorderEffect
@onready var screen_border_animation = $ScreenBorderAnimation

@onready var doors = [
	$DoorsUp,
	$DoorsBottom,
	$DoorsLeft,
	$DoorsRight
]
@onready var equation_label = $Equation
@onready var timer = $Timer  # Timer node for animations
@onready var character = $Character  # AnimatedSprite2D node for the player
@onready var space_to_start_label = $StartMessage
@onready var rules_label = $Rules

# Positions to walk to
@onready var door_positions = [
	doors[0].position,
	doors[1].position,
	Vector2(doors[2].position.x, doors[2].position.y - 40),
	Vector2(doors[3].position.x, doors[3].position.y - 40),
]

func _ready() -> void:
	setup_log_file()
	display_start_prompt()
	generate_round()
	
func display_start_prompt():
	equation_label.hide()
	character.hide()
	space_to_start_label.show()
	rules_label.show()

func setup_log_file():
	var current_date = Time.get_datetime_string_from_system(false)
	current_date = current_date.replace(":", "").replace("-", "")
	log_file_name = Globals.username + "_" + current_date + ".csv"

func generate_round():
	is_input_enabled = true
	current_door_index = -1  # Reset selected door
	character.position = Vector2(0, -40)  # Reset player to center of the room
	character.play("stand")  # Play standing animation

	if total_rounds >= MAX_ROUNDS:
		end_game()
		return

	total_rounds += 1
	round_start_time = Time.get_ticks_msec()
	
	# Generate equation
	var num1 = randi() % 10 + 1
	var num2 = randi() % 10 + 1
	var is_addition = randi() % 2 == 0

	correct_answer = num1 + num2 if is_addition else num1 - num2
	equation_label.text = str(num1) + (" + " if is_addition else " - ") + str(num2)

	# Shuffle answers
	var answers = [correct_answer]
	while answers.size() < 4:
		var random_answer = randi() % 20 - 5
		if random_answer not in answers and random_answer >= 0:
			answers.append(random_answer)
	answers.shuffle()

	for i in range(doors.size()):
		var answer_label = doors[i].get_node_or_null("Answer")
		if answer_label:
			answer_label.text = str(answers[i])
		else:
			print("error. missing answer node in door")

func check_answer(selected_index):
	if not is_input_enabled: return
	
	var selected_door = doors[selected_index]
	var answer_label = selected_door.get_node_or_null("Answer")
	if answer_label:
		var selected_answer = int(answer_label.text)
		var time_taken = Time.get_ticks_msec() - round_start_time  # Calculate time taken

		# Update scores
		if selected_answer == correct_answer:
			Globals.correct_score += 1
			animate_border(true)
		else:
			Globals.incorrect_score += 1
			animate_border(false)
		
		# Log the entry
		log_entry(equation_label.text, str(selected_answer), time_taken)
	
	is_input_enabled = false  # Lock input during the movement
	current_door_index = selected_index
	var target_position = door_positions[selected_index]

	# Move the character toward the door
	move_character_to_door(target_position)

func move_character_to_door(target_position: Vector2):
	# Determine direction and play correct animation
	var direction = (target_position - character.position).normalized()
	equation_label.visible = false

	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			character.play("walk_right")
		else:
			character.play("walk_left")
	else:
		if direction.y > 0:
			character.play("walk_down")
		else:
			character.play("walk_up")

	# Use Tween to move the character
	var tween = create_tween()
	tween.tween_property(character, "position", target_position, 1.5)  # Adjust time for speed
	tween.finished.connect(_on_character_reached_door)

func _on_character_reached_door():
	character.visible = false

	var selected_door = doors[current_door_index]
	var answer_label = selected_door.get_node_or_null("Answer")
	if answer_label:
		open_door(selected_door, answer_label)

func open_door(door: Sprite2D, answer_label: Label):
	# Open the door
	door.region_enabled = true
	door.region_rect = Rect2(6, 116, 16, 28)
	answer_label.visible = false  # Hide label

	if timer.is_connected("timeout", Callable(self, "_on_character_entered_door")):
		timer.disconnect("timeout", Callable(self, "_on_character_entered_door"))
	
	timer.connect("timeout", Callable(self, "_on_character_entered_door").bind(door, answer_label))
	timer.start(1)

func _on_character_entered_door(door: Sprite2D, answer_label: Label):

	# Close the door
	door.region_rect = Rect2(24, 116, 16, 28)  # Closed door region
	answer_label.visible = true  # Show label again

	# Reset the round
	timer.stop()
	equation_label.visible = true
	character.visible = true  # Make the character visible again
	generate_round()

func _input(event):
	if not game_started:
		if event.is_action_pressed("ui_select"):  # Space bar pressed
			game_started = true
			space_to_start_label.hide()
			rules_label.hide()
			character.show()
			equation_label.show()
		elif event.is_action_pressed("ui_cancel"):  # Escape button
				save_log_to_file()
				get_tree().quit()
	else:
		if not is_input_enabled:
			return
		if event.is_action_pressed("ui_up"):
			check_answer(0)
		elif event.is_action_pressed("ui_down"):
			check_answer(1)
		elif event.is_action_pressed("ui_left"):
			check_answer(2)
		elif event.is_action_pressed("ui_right"):
			check_answer(3)
		elif event.is_action_pressed("ui_cancel"):
			save_log_to_file()
			get_tree().quit()

func end_game():
	save_log_to_file()
	var end_scene_path = "res://scenes/EndScene.tscn"
	if ResourceLoader.exists(end_scene_path):
		get_tree().change_scene_to_file(end_scene_path)
	else:
		push_error("End scene file not found: " + end_scene_path)

func save_log_to_file():
	var file_path = "user://mathematicalmaze_data/" + log_file_name
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_line("Number;Equation;Answer;Time(ms)")
		for entry in log_entries:
			file.store_line(entry)
		file.close()
		print("Log saved to: " + file_path)
	else:
		print("Failed to save log file")

func log_entry(equation: String, answer: String, time: int):
	var entry = "%d;%s;%s;%dms" % [log_entries.size() + 1, equation, answer, time]
	log_entries.append(entry)

func animate_border(is_correct: bool) -> void:
	# Set the border color based on whether the answer was correct
	var target_color = Color(0, 1, 0, 1) if is_correct else Color(1, 0, 0, 1)
	screen_border_effect.color = target_color
	
	# Play the animation
	screen_border_animation.play("BorderFlash")
