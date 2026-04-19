extends Node

## Autoload: Settings
## Хранит пользовательские настройки (сейчас только locale) в user://settings.cfg
## и применяет их на старте.

const CONFIG_PATH := "user://settings.cfg"
const DEFAULT_LOCALE := "ru"

var locale: String = DEFAULT_LOCALE


func _ready() -> void:
	_load()
	TranslationServer.set_locale(locale)


func set_locale(new_locale: String) -> void:
	if new_locale == locale:
		return
	locale = new_locale
	TranslationServer.set_locale(locale)
	_save()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	locale = cfg.get_value("settings", "locale", DEFAULT_LOCALE)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "locale", locale)
	cfg.save(CONFIG_PATH)
