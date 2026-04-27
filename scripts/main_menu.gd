extends Control

const LEVEL_PATH := "res://scenes/levels/level_01.tscn"
const SETTINGS_MENU_PATH := "res://scenes/menu/settings_menu.tscn"
const FADE_DURATION := 0.25
const SILENCE_AFTER_FADE := 0.5
const NAV_COOLDOWN := 0.18
const INPUT_BLOCK_DURATION := 0.5

@onready var title: Label = $Panel/VBox/Title
@onready var subtitle: Label = $Panel/VBox/Subtitle
@onready var start_button: Button = $Panel/VBox/StartButton
@onready var settings_button: Button = $Panel/VBox/SettingsButton
@onready var quit_button: Button = $Panel/VBox/QuitButton
@onready var black_fade: ColorRect = $BlackFade

var _transitioning := false
var _nav_cooldown := 0.0
var _input_block := 0.0


func _ready() -> void:
	MusicManager.set_state(MusicManager.State.MENU)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_input_block = INPUT_BLOCK_DURATION

	TranslationServer.set_locale(Settings.locale)

	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	_refresh_labels()
	start_button.grab_focus()


func _process(delta: float) -> void:
	if _nav_cooldown > 0.0:
		_nav_cooldown -= delta
	if _input_block > 0.0:
		_input_block -= delta


func _input(event: InputEvent) -> void:
	if _input_block > 0.0 and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		return

	# Suppress rapid ui_up/ui_down within NAV_COOLDOWN — holding a stick/key
	# would otherwise skip several menu items per input pulse.
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") \
			or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		if _nav_cooldown > 0.0:
			get_viewport().set_input_as_handled()
			return
		_nav_cooldown = NAV_COOLDOWN


func _refresh_labels() -> void:
	title.text = tr("menu.title")
	subtitle.text = tr("menu.subtitle")
	start_button.text = tr("menu.start")
	settings_button.text = tr("menu.settings")
	quit_button.text = tr("menu.quit")


func _on_settings_pressed() -> void:
	if _transitioning:
		return
	get_tree().change_scene_to_file(SETTINGS_MENU_PATH)


func _on_start_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	start_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true

	var tw := create_tween().set_parallel(true)
	tw.tween_property(black_fade, "color:a", 1.0, FADE_DURATION)
	MusicManager.set_state(MusicManager.State.SILENT)

	await get_tree().create_timer(FADE_DURATION + SILENCE_AFTER_FADE).timeout
	get_tree().change_scene_to_file(LEVEL_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
