extends CanvasLayer

@onready var timer_label: Label = $TimerLabel
@onready var mode_label: Label = $ModeLabel
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/VBox/ResultLabel
@onready var result_hint: Label = $ResultPanel/VBox/HintLabel
@onready var hints_bar: Label = $HintsBar

var _showing_result := false
var _active_hints: Array = []   # [["action", "hint_key"], ...]


func _ready() -> void:
	timer_label.visible = false
	mode_label.visible = false
	result_panel.visible = false
	hints_bar.visible = false
	InputDevice.device_changed.connect(_refresh_all_hints)


func show_timer(seconds: float) -> void:
	timer_label.visible = true
	update_timer(seconds)


func update_timer(seconds: float) -> void:
	var clamped := maxf(seconds, 0.0)
	var mins: int = int(clamped) / 60
	var secs: int = int(clamped) % 60
	var ms: int = int(fmod(clamped, 1.0) * 1000)
	timer_label.text = "%d:%02d.%03d" % [mins, secs, ms]


func hide_timer() -> void:
	timer_label.visible = false


func show_mode(is_mop: bool) -> void:
	mode_label.visible = true
	mode_label.text = tr("hud.mode.mop") if is_mop else tr("hud.mode.guns")


## hints — array of pairs: [["action_name", "hint_key"], ...]
## Example: [["interact", "hud.hint.pickup"], ["toggle_mop", "hud.hint.toggle_mop"]]
func set_hints(hints: Array) -> void:
	_active_hints = hints
	_refresh_all_hints()


func clear_hints() -> void:
	_active_hints = []
	hints_bar.visible = false


func _refresh_all_hints() -> void:
	if _active_hints.is_empty():
		hints_bar.visible = false
		return
	var parts: Array = []
	for pair in _active_hints:
		var action: String = pair[0]
		var key: String   = pair[1]
		parts.append("%s %s" % [InputDevice.get_hint_text(action), tr(key)])
	hints_bar.text = "   ".join(parts)
	hints_bar.visible = true
	if _showing_result:
		result_hint.text = "%s %s" % [InputDevice.get_hint_text("ui_accept"), tr("hud.hint.return")]


func show_gameover(reason: String) -> void:
	_showing_result = true
	result_panel.visible = true
	match reason:
		"combat":
			result_label.text = tr("result.dead")
		"exit_early":
			result_label.text = tr("result.exit_early")
		"timer":
			result_label.text = tr("result.timer")
		_:
			result_label.text = tr("result.dead")
	result_hint.text = "%s %s" % [InputDevice.get_hint_text("ui_accept"), tr("hud.hint.return")]


func show_victory() -> void:
	_showing_result = true
	result_panel.visible = true
	result_label.text = "%s\n\n%s\n%s" % [
		tr("result.victory.title"),
		tr("result.victory.body"),
		tr("result.victory.outro"),
	]
	result_hint.text = "%s %s" % [InputDevice.get_hint_text("ui_accept"), tr("hud.hint.return")]


func _unhandled_input(event: InputEvent) -> void:
	if _showing_result and event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
