extends Node

## Autoload: Settings
## Persists user preferences (locale, difficulty) to user://settings.cfg
## and applies them on startup.

const CONFIG_PATH := "user://settings.cfg"
const DEFAULT_LOCALE := "en"
const DEFAULT_DIFFICULTY := "normal"

var locale: String = DEFAULT_LOCALE
var difficulty: String = DEFAULT_DIFFICULTY


func _ready() -> void:
	_load()
	TranslationServer.set_locale(locale)


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


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	locale = cfg.get_value("settings", "locale", DEFAULT_LOCALE)
	difficulty = cfg.get_value("settings", "difficulty", DEFAULT_DIFFICULTY)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "locale", locale)
	cfg.set_value("settings", "difficulty", difficulty)
	cfg.save(CONFIG_PATH)
