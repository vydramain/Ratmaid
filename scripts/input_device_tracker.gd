extends Node

## Tracks the active input device type and gamepad brand.
## Autoload singleton: InputDevice

enum DeviceType { KEYBOARD_MOUSE, GAMEPAD }
enum GamepadBrand { XBOX, PLAYSTATION }

signal device_changed

var current_type: DeviceType = DeviceType.KEYBOARD_MOUSE
var gamepad_brand: GamepadBrand = GamepadBrand.XBOX

const _TEXT_KB := {
	"interact":    "E",
	"toggle_mop":  "Tab",
	"shoot":       "LMB",
	"ui_accept":   "Enter",
	"pause":       "Esc",
	"restart_tap": "R",
}
const _TEXT_XBOX := {
	"interact":     "A",
	"toggle_mop":   "D-pad ↑",
	"shoot":        "RT",
	"ui_accept":    "A",
	"pause":        "Start",
	"restart_hold": "A",
}
const _TEXT_PS := {
	"interact":     "×",
	"toggle_mop":   "D-pad ↑",
	"shoot":        "R2",
	"ui_accept":    "×",
	"pause":        "Options",
	"restart_hold": "×",
}

# Icon paths. Falls back to text label if the file does not exist.
const _ICON_PATHS := {
	"keyboard": {
		"interact":   "res://images/icons/keyboard/key_e.png",
		"toggle_mop": "res://images/icons/keyboard/key_tab.png",
		"shoot":      "res://images/icons/keyboard/key_lmb.png",
		"ui_accept":  "res://images/icons/keyboard/key_enter.png",
	},
	"xbox": {
		"interact":   "res://images/icons/xbox/button_a.png",
		"toggle_mop": "res://images/icons/xbox/dpad_up.png",
		"shoot":      "res://images/icons/xbox/button_rt.png",
		"ui_accept":  "res://images/icons/xbox/button_a.png",
	},
	"playstation": {
		"interact":   "res://images/icons/playstation/button_cross.png",
		"toggle_mop": "res://images/icons/playstation/dpad_up.png",
		"shoot":      "res://images/icons/playstation/button_r2.png",
		"ui_accept":  "res://images/icons/playstation/button_cross.png",
	},
}


func _input(event: InputEvent) -> void:
	var prev := current_type
	if event is InputEventKey or event is InputEventMouseButton:
		current_type = DeviceType.KEYBOARD_MOUSE
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		current_type = DeviceType.GAMEPAD
		_detect_brand()
	if current_type != prev:
		emit_signal("device_changed")


func _detect_brand() -> void:
	for i in range(4):
		if Input.is_joy_known(i):
			var joy := Input.get_joy_name(i).to_lower()
			if "dualsense" in joy or "dualshock" in joy or "playstation" in joy or "ps4" in joy or "ps5" in joy:
				gamepad_brand = GamepadBrand.PLAYSTATION
			else:
				gamepad_brand = GamepadBrand.XBOX
			return


## Returns a text hint label: "[E]", "[A]", "[×]", etc.
func get_hint_text(action: String) -> String:
	var table: Dictionary
	if current_type == DeviceType.KEYBOARD_MOUSE:
		table = _TEXT_KB
	elif gamepad_brand == GamepadBrand.PLAYSTATION:
		table = _TEXT_PS
	else:
		table = _TEXT_XBOX
	var key: String = table.get(action, "?")
	return "[%s]" % key


## Returns the icon texture for an action, or null if the file does not exist.
func get_hint_icon(action: String) -> Texture2D:
	var device_key: String = _device_key()
	if not _ICON_PATHS.has(device_key):
		return null
	var sub: Dictionary = _ICON_PATHS[device_key]
	if not sub.has(action):
		return null
	var path: String = sub[action]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _device_key() -> String:
	if current_type == DeviceType.KEYBOARD_MOUSE:
		return "keyboard"
	return "playstation" if gamepad_brand == GamepadBrand.PLAYSTATION else "xbox"


func is_gamepad() -> bool:
	return current_type == DeviceType.GAMEPAD
