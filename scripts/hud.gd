extends CanvasLayer

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"
const RESTART_HOLD_DURATION := 1.0

@onready var timer_label: Label = $TimerLabel
@onready var mode_label: Label = $ModeLabel
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/VBox/ResultLabel
@onready var restart_hint: Label = $ResultPanel/VBox/RestartHintLabel
@onready var restart_progress: ProgressBar = $ResultPanel/VBox/RestartProgress
@onready var menu_hint: Label = $ResultPanel/VBox/MenuHintLabel
@onready var hints_bar: Label = $HintsBar
@onready var pause_menu: Control = $PauseMenu

var _showing_result := false
var _allow_restart := false
var _is_paused := false
var _active_hints: Array = []   # [["action", "hint_key"], ...]
var _restart_hold_time := 0.0


func _ready() -> void:
	timer_label.visible = false
	mode_label.visible = false
	result_panel.visible = false
	hints_bar.visible = false
	restart_hint.visible = false
	restart_progress.visible = false
	pause_menu.pause_closed.connect(_resume)
	pause_menu.exit_to_main_menu_requested.connect(_exit_to_main_menu)
	InputDevice.device_changed.connect(_on_device_changed)


func _process(delta: float) -> void:
	if not _showing_result or not _allow_restart:
		return
	if Input.is_action_pressed("restart_hold"):
		_restart_hold_time += delta
		restart_progress.value = clampf(_restart_hold_time / RESTART_HOLD_DURATION, 0.0, 1.0) * 100.0
		if _restart_hold_time >= RESTART_HOLD_DURATION:
			_restart_level()
	elif _restart_hold_time > 0.0:
		_restart_hold_time = 0.0
		restart_progress.value = 0.0


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
	_refresh_hints_bar()


func clear_hints() -> void:
	_active_hints = []
	hints_bar.visible = false


func _refresh_hints_bar() -> void:
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


func _on_device_changed() -> void:
	_refresh_hints_bar()
	if _showing_result:
		_refresh_result_hints()


func show_gameover(reason: String) -> void:
	_showing_result = true
	_allow_restart = true
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
	_refresh_result_hints()


func show_victory() -> void:
	_showing_result = true
	_allow_restart = false
	result_panel.visible = true
	result_label.text = "%s\n\n%s\n%s" % [
		tr("result.victory.title"),
		tr("result.victory.body"),
		tr("result.victory.outro"),
	]
	_refresh_result_hints()


func _refresh_result_hints() -> void:
	menu_hint.text = "%s %s" % [InputDevice.get_hint_text("pause"), tr("hud.hint.return")]
	if not _allow_restart:
		restart_hint.visible = false
		restart_progress.visible = false
		return
	if InputDevice.is_gamepad():
		restart_hint.text = "%s %s" % [InputDevice.get_hint_text("restart_hold"), tr("hud.hint.restart_hold")]
		restart_progress.visible = true
	else:
		restart_hint.text = "%s %s" % [InputDevice.get_hint_text("restart_tap"), tr("hud.hint.restart_tap")]
		restart_progress.visible = false
		restart_progress.value = 0.0
		_restart_hold_time = 0.0
	restart_hint.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if _showing_result:
			_exit_to_main_menu()
		elif not _is_paused:
			_pause()
		return
	if _showing_result and _allow_restart and event.is_action_pressed("restart_tap"):
		get_viewport().set_input_as_handled()
		_restart_level()


func _pause() -> void:
	if _is_paused:
		return
	_is_paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_menu.open()
	get_tree().paused = true


func _resume() -> void:
	if not _is_paused:
		return
	get_tree().paused = false
	pause_menu.close()
	_is_paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _restart_level() -> void:
	if not _allow_restart:
		return
	_allow_restart = false
	_restart_hold_time = 0.0
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	# Defer to the idle frame so any in-flight input handling on this HUD
	# finishes before the scene (and this node) gets replaced.
	get_tree().call_deferred("reload_current_scene")


func _exit_to_main_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_deferred("change_scene_to_file", MAIN_MENU_PATH)
