extends Control


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LoginScene.tscn")
	
	
func _on_data_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/FileManager.tscn")


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
