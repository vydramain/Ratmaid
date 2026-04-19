extends Control

const LEVEL_PATH := "res://scenes/levels/level_01.tscn"
const LOCALES: Array[String] = ["ru", "en"]
const FADE_DURATION := 0.25
const SILENCE_AFTER_FADE := 0.5

@onready var start_button: Button = $Panel/VBox/StartButton
@onready var quit_button: Button = $Panel/VBox/QuitButton
@onready var lang_button: Button = $Panel/VBox/LangButton
@onready var black_fade: ColorRect = $BlackFade

var _locale_index := 0
var _transitioning := false


func _ready() -> void:
	MusicManager.set_state(MusicManager.State.MENU)

	_locale_index = LOCALES.find(Settings.locale)
	if _locale_index < 0:
		_locale_index = 0
	TranslationServer.set_locale(LOCALES[_locale_index])

	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	lang_button.pressed.connect(_on_lang_pressed)

	_refresh_labels()
	start_button.grab_focus()


func _refresh_labels() -> void:
	start_button.text = tr("menu.start")
	quit_button.text = tr("menu.quit")
	lang_button.text = "[ %s ]" % LOCALES[_locale_index].to_upper()


func _on_lang_pressed() -> void:
	_locale_index = (_locale_index + 1) % LOCALES.size()
	Settings.set_locale(LOCALES[_locale_index])
	_refresh_labels()


func _on_start_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	start_button.disabled = true
	quit_button.disabled = true
	lang_button.disabled = true

	var tw := create_tween().set_parallel(true)
	tw.tween_property(black_fade, "color:a", 1.0, FADE_DURATION)
	MusicManager.set_state(MusicManager.State.SILENT)

	await get_tree().create_timer(FADE_DURATION + SILENCE_AFTER_FADE).timeout
	get_tree().change_scene_to_file(LEVEL_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
