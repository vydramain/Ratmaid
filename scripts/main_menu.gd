extends Control

const LEVEL_PATH := "res://scenes/levels/level_01.tscn"


func _ready() -> void:
	MusicManager.set_state(MusicManager.State.MENU)
	$Panel/VBox/StartButton.grab_focus()
	$Panel/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
