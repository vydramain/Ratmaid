extends Control

const LEVEL_PATH := "res://scenes/levels/level_01.tscn"
const LOCALES: Array[String] = ["ru", "en"]
const DIFFICULTIES: Array[String] = ["normal", "hard"]
const FADE_DURATION := 0.25
const SILENCE_AFTER_FADE := 0.5
const NAV_COOLDOWN := 0.18
const INPUT_BLOCK_DURATION := 0.5

@onready var title: Label = $Panel/VBox/Title
@onready var subtitle: Label = $Panel/VBox/Subtitle
@onready var start_button: Button = $Panel/VBox/StartButton
@onready var quit_button: Button = $Panel/VBox/QuitButton
@onready var lang_button: Button = $Panel/VBox/LangButton
@onready var difficulty_button: Button = $Panel/VBox/DifficultyButton
@onready var black_fade: ColorRect = $BlackFade

var _locale_index := 0
var _difficulty_index := 0
var _transitioning := false
var _nav_cooldown := 0.0
var _input_block := 0.0


func _ready() -> void:
	MusicManager.set_state(MusicManager.State.MENU)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_input_block = INPUT_BLOCK_DURATION

	_locale_index = LOCALES.find(Settings.locale)
	if _locale_index < 0:
		_locale_index = 0
	TranslationServer.set_locale(LOCALES[_locale_index])

	_difficulty_index = DIFFICULTIES.find(Settings.difficulty)
	if _difficulty_index < 0:
		_difficulty_index = 0

	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	lang_button.pressed.connect(_on_lang_pressed)
	difficulty_button.pressed.connect(_on_difficulty_pressed)

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

	# Гасим повторные ui_up/ui_down в пределах NAV_COOLDOWN — иначе при
	# держании стика/клавиши фокус проскакивает несколько пунктов за один импульс.
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
	quit_button.text = tr("menu.quit")
	lang_button.text = "[ %s ]" % LOCALES[_locale_index].to_upper()
	difficulty_button.text = "[ %s ]" % tr("difficulty." + DIFFICULTIES[_difficulty_index])


func _on_lang_pressed() -> void:
	_locale_index = (_locale_index + 1) % LOCALES.size()
	Settings.set_locale(LOCALES[_locale_index])
	_refresh_labels()


func _on_difficulty_pressed() -> void:
	_difficulty_index = (_difficulty_index + 1) % DIFFICULTIES.size()
	Settings.set_difficulty(DIFFICULTIES[_difficulty_index])
	_refresh_labels()


func _on_start_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	start_button.disabled = true
	quit_button.disabled = true
	lang_button.disabled = true
	difficulty_button.disabled = true

	var tw := create_tween().set_parallel(true)
	tw.tween_property(black_fade, "color:a", 1.0, FADE_DURATION)
	MusicManager.set_state(MusicManager.State.SILENT)

	await get_tree().create_timer(FADE_DURATION + SILENCE_AFTER_FADE).timeout
	get_tree().change_scene_to_file(LEVEL_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
