extends Control

## Settings panel. Used as a standalone scene from the main menu, or
## instantiated as an overlay child by the pause menu (embedded mode).

signal settings_closed

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"
const LOCALES: Array[String] = ["ru", "en"]
const DIFFICULTIES: Array[String] = ["normal", "hard"]
const NAV_COOLDOWN := 0.18
const INPUT_BLOCK_DURATION := 0.5

@onready var title: Label = $Panel/VBox/Title
@onready var difficulty_label: Label = $Panel/VBox/DifficultyRow/Label
@onready var difficulty_button: Button = $Panel/VBox/DifficultyRow/Value
@onready var language_label: Label = $Panel/VBox/LanguageRow/Label
@onready var language_button: Button = $Panel/VBox/LanguageRow/Value
@onready var master_label: Label = $Panel/VBox/MasterVolumeRow/Label
@onready var master_slider: HSlider = $Panel/VBox/MasterVolumeRow/Slider
@onready var master_value: Label = $Panel/VBox/MasterVolumeRow/Value
@onready var music_label: Label = $Panel/VBox/MusicVolumeRow/Label
@onready var music_slider: HSlider = $Panel/VBox/MusicVolumeRow/Slider
@onready var music_value: Label = $Panel/VBox/MusicVolumeRow/Value
@onready var sfx_label: Label = $Panel/VBox/SfxVolumeRow/Label
@onready var sfx_slider: HSlider = $Panel/VBox/SfxVolumeRow/Slider
@onready var sfx_value: Label = $Panel/VBox/SfxVolumeRow/Value
@onready var fullscreen_label: Label = $Panel/VBox/FullscreenRow/Label
@onready var fullscreen_button: Button = $Panel/VBox/FullscreenRow/Value
@onready var back_button: Button = $Panel/VBox/BackButton

var _locale_index := 0
var _difficulty_index := 0
var _nav_cooldown := 0.0
var _input_block := 0.0
var _embedded := false


func set_embedded(value: bool) -> void:
	_embedded = value


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_input_block = INPUT_BLOCK_DURATION

	_locale_index = LOCALES.find(Settings.locale)
	if _locale_index < 0:
		_locale_index = 0
	_difficulty_index = DIFFICULTIES.find(Settings.difficulty)
	if _difficulty_index < 0:
		_difficulty_index = 0

	master_slider.value = Settings.master_volume
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume
	fullscreen_button.button_pressed = Settings.fullscreen

	difficulty_button.pressed.connect(_on_difficulty_pressed)
	language_button.pressed.connect(_on_language_pressed)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_button.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_return_to_menu)

	_refresh_labels()
	difficulty_button.grab_focus()


func _process(delta: float) -> void:
	if _nav_cooldown > 0.0:
		_nav_cooldown -= delta
	if _input_block > 0.0:
		_input_block -= delta


func _input(event: InputEvent) -> void:
	if _input_block > 0.0 and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		_return_to_menu()
		get_viewport().set_input_as_handled()
		return

	# Mirror main_menu's nav cooldown so held input doesn't skip rows.
	# Slider adjustment uses ui_left/ui_right while focused, so leave those alone.
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		if _nav_cooldown > 0.0:
			get_viewport().set_input_as_handled()
			return
		_nav_cooldown = NAV_COOLDOWN


func _refresh_labels() -> void:
	title.text = tr("settings.title")
	difficulty_label.text = tr("settings.difficulty")
	difficulty_button.text = "[ %s ]" % tr("difficulty." + DIFFICULTIES[_difficulty_index])
	language_label.text = tr("settings.language")
	language_button.text = "[ %s ]" % LOCALES[_locale_index].to_upper()
	master_label.text = tr("settings.master_volume")
	music_label.text = tr("settings.music_volume")
	sfx_label.text = tr("settings.sfx_volume")
	fullscreen_label.text = tr("settings.fullscreen")
	fullscreen_button.text = "[ %s ]" % tr("settings.on" if fullscreen_button.button_pressed else "settings.off")
	back_button.text = tr("settings.back")
	_refresh_volume_label(master_value, master_slider.value)
	_refresh_volume_label(music_value, music_slider.value)
	_refresh_volume_label(sfx_value, sfx_slider.value)


func _refresh_volume_label(label: Label, value: float) -> void:
	label.text = "%d%%" % roundi(value * 100.0)


func _on_difficulty_pressed() -> void:
	_difficulty_index = (_difficulty_index + 1) % DIFFICULTIES.size()
	Settings.set_difficulty(DIFFICULTIES[_difficulty_index])
	_refresh_labels()


func _on_language_pressed() -> void:
	_locale_index = (_locale_index + 1) % LOCALES.size()
	Settings.set_locale(LOCALES[_locale_index])
	_refresh_labels()


func _on_master_changed(value: float) -> void:
	Settings.set_master_volume(value)
	_refresh_volume_label(master_value, value)


func _on_music_changed(value: float) -> void:
	Settings.set_music_volume(value)
	_refresh_volume_label(music_value, value)


func _on_sfx_changed(value: float) -> void:
	Settings.set_sfx_volume(value)
	_refresh_volume_label(sfx_value, value)


func _on_fullscreen_toggled(pressed: bool) -> void:
	Settings.set_fullscreen(pressed)
	_refresh_labels()


func _return_to_menu() -> void:
	if _embedded:
		emit_signal("settings_closed")
	else:
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
