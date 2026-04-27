extends Control

## Pause menu shown over the level when the player presses the pause action.
## Hosts three actions (resume, settings, exit to main menu) and can embed the
## settings menu as an overlay so the level scene stays alive underneath.

signal pause_closed
signal exit_to_main_menu_requested

const SETTINGS_MENU_SCENE := preload("res://scenes/menu/settings_menu.tscn")
const NAV_COOLDOWN := 0.18
const INPUT_BLOCK_DURATION := 0.25

@onready var panel: CenterContainer = $Panel
@onready var background: ColorRect = $Background
@onready var title: Label = $Panel/VBox/Title
@onready var continue_button: Button = $Panel/VBox/ContinueButton
@onready var settings_button: Button = $Panel/VBox/SettingsButton
@onready var main_menu_button: Button = $Panel/VBox/MainMenuButton

var _embedded_settings: Control = null
var _nav_cooldown := 0.0
var _input_block := 0.0


func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)


func open() -> void:
	visible = true
	panel.visible = true
	background.visible = true
	_input_block = INPUT_BLOCK_DURATION
	_refresh_labels()
	continue_button.grab_focus()


func close() -> void:
	visible = false
	if _embedded_settings != null:
		_embedded_settings.queue_free()
		_embedded_settings = null


func is_settings_open() -> bool:
	return _embedded_settings != null


func _process(delta: float) -> void:
	if _nav_cooldown > 0.0:
		_nav_cooldown -= delta
	if _input_block > 0.0:
		_input_block -= delta


func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Suppress carry-over from the press that opened the menu.
	if _input_block > 0.0 and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause"):
		if _embedded_settings != null:
			_close_embedded_settings()
		else:
			emit_signal("pause_closed")
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		if _nav_cooldown > 0.0:
			get_viewport().set_input_as_handled()
			return
		_nav_cooldown = NAV_COOLDOWN


func _refresh_labels() -> void:
	title.text = tr("pause.title")
	continue_button.text = tr("pause.continue")
	settings_button.text = tr("pause.settings")
	main_menu_button.text = tr("pause.main_menu")


func _on_continue_pressed() -> void:
	emit_signal("pause_closed")


func _on_settings_pressed() -> void:
	var settings: Control = SETTINGS_MENU_SCENE.instantiate()
	settings.process_mode = Node.PROCESS_MODE_ALWAYS
	settings.set_embedded(true)
	settings.settings_closed.connect(_close_embedded_settings)
	add_child(settings)
	_embedded_settings = settings
	panel.visible = false
	background.visible = false


func _close_embedded_settings() -> void:
	if _embedded_settings != null:
		_embedded_settings.queue_free()
		_embedded_settings = null
	panel.visible = true
	background.visible = true
	_refresh_labels()
	continue_button.grab_focus()


func _on_main_menu_pressed() -> void:
	emit_signal("exit_to_main_menu_requested")
