extends Node

## Autoload: Settings
## Persists user preferences (locale, difficulty, audio volumes) to
## user://settings.cfg and applies them on startup.

const CONFIG_PATH := "user://settings.cfg"
const DEFAULT_LOCALE := "en"
const DEFAULT_DIFFICULTY := "normal"
const DEFAULT_VOLUME := 1.0
const DEFAULT_FULLSCREEN := true

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const SILENT_DB := -80.0

var locale: String = DEFAULT_LOCALE
var difficulty: String = DEFAULT_DIFFICULTY
var master_volume: float = DEFAULT_VOLUME
var music_volume: float = DEFAULT_VOLUME
var sfx_volume: float = DEFAULT_VOLUME
var fullscreen: bool = DEFAULT_FULLSCREEN


func _ready() -> void:
	_load()
	TranslationServer.set_locale(locale)
	_apply_bus_volume(BUS_MASTER, master_volume)
	_apply_bus_volume(BUS_MUSIC, music_volume)
	_apply_bus_volume(BUS_SFX, sfx_volume)
	_apply_fullscreen(fullscreen)


func set_locale(new_locale: String) -> void:
	if new_locale == locale:
		return
	locale = new_locale
	TranslationServer.set_locale(locale)
	_save()


func set_difficulty(new_difficulty: String) -> void:
	if new_difficulty == difficulty:
		return
	difficulty = new_difficulty
	_save()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(BUS_MASTER, master_volume)
	_save()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(BUS_MUSIC, music_volume)
	_save()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(BUS_SFX, sfx_volume)
	_save()


func set_fullscreen(value: bool) -> void:
	if value == fullscreen:
		return
	fullscreen = value
	_apply_fullscreen(fullscreen)
	_save()


func _apply_fullscreen(value: bool) -> void:
	# Project defaults to mode=3 + borderless=true. The borderless flag persists
	# across mode changes, so a plain mode swap leaves windowed mode without
	# decorations. Drive both flags explicitly to match Project Settings behaviour.
	if value:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)


func _apply_bus_volume(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var db := SILENT_DB if value <= 0.0 else linear_to_db(value)
	AudioServer.set_bus_volume_db(idx, db)
	AudioServer.set_bus_mute(idx, value <= 0.0)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	locale = cfg.get_value("settings", "locale", DEFAULT_LOCALE)
	difficulty = cfg.get_value("settings", "difficulty", DEFAULT_DIFFICULTY)
	master_volume = clampf(cfg.get_value("settings", "master_volume", DEFAULT_VOLUME), 0.0, 1.0)
	music_volume = clampf(cfg.get_value("settings", "music_volume", DEFAULT_VOLUME), 0.0, 1.0)
	sfx_volume = clampf(cfg.get_value("settings", "sfx_volume", DEFAULT_VOLUME), 0.0, 1.0)
	fullscreen = cfg.get_value("settings", "fullscreen", DEFAULT_FULLSCREEN)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "locale", locale)
	cfg.set_value("settings", "difficulty", difficulty)
	cfg.set_value("settings", "master_volume", master_volume)
	cfg.set_value("settings", "music_volume", music_volume)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.save(CONFIG_PATH)
