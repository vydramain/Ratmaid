extends CanvasLayer

signal dialogue_finished

const TYPEWRITER_SPEED := 0.03  # seconds per character

## Dialogue sets. Each entry: { "speaker": "signal"|"maid", "key": "dialogue.*" }
## Speaker determines which AudioStreamPlayer ticks during typewriting.
const SETS: Dictionary = {
	"intro": [
		{"speaker": "maid", "key": "dialogue.intro.maid"},
	],
	"after_fight": [
		{"speaker": "signal", "key": "dialogue.after_fight.signal"},
		{"speaker": "maid", "key": "dialogue.after_fight.maid"},
	],
}

var _lines: Array = []
var _current_line := 0
var _current_text := ""
var _current_speaker := ""
var _char_index := 0
var _timer := 0.0
var _is_animating := false

@onready var text_label: RichTextLabel = $Panel/VBox/TextLabel
@onready var hint_label: Label = $Panel/VBox/HintLabel
@onready var type_sfx: Dictionary = {
	"signal": $TypeSfxSignal,
	"maid": $TypeSfxMaid,
}


func _ready() -> void:
	visible = false
	InputDevice.device_changed.connect(_refresh_hints)


func start_dialogue(set_name: String) -> void:
	_lines = SETS.get(set_name, [])
	if _lines.is_empty():
		emit_signal("dialogue_finished")
		return
	_current_line = 0
	visible = true
	_show_line(_current_line)


func _show_line(_index: int) -> void:
	var entry: Dictionary = _lines[_current_line]
	_current_speaker = entry["speaker"]
	_current_text = "[%s] %s" % [tr("speaker." + _current_speaker), tr(entry["key"])]
	text_label.text = ""
	_char_index = 0
	_timer = 0.0
	_is_animating = true
	_refresh_hints()


func _process(delta: float) -> void:
	if not _is_animating:
		return
	_timer += delta
	if _timer >= TYPEWRITER_SPEED:
		_timer -= TYPEWRITER_SPEED
		_char_index += 1
		var ch := _current_text.substr(_char_index - 1, 1)
		text_label.text = _current_text.substr(0, _char_index)
		_play_type_sfx(ch)
		if _char_index >= _current_text.length():
			_is_animating = false
			_refresh_hints()


func _play_type_sfx(ch: String) -> void:
	if ch.strip_edges() == "":
		return  # no tick on spaces or line breaks
	var player: AudioStreamPlayer = type_sfx.get(_current_speaker)
	if player == null or player.stream == null:
		return
	player.stop()
	player.play()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		if _is_animating:
			text_label.text = _current_text
			_char_index = _current_text.length()
			_is_animating = false
			_refresh_hints()
		else:
			_advance_line()
		get_viewport().set_input_as_handled()


func _advance_line() -> void:
	_current_line += 1
	if _current_line >= _lines.size():
		visible = false
		emit_signal("dialogue_finished")
	else:
		_show_line(_current_line)


func _refresh_hints() -> void:
	var btn := InputDevice.get_hint_text("ui_accept")
	if _is_animating:
		hint_label.text = "%s %s" % [btn, tr("hud.hint.skip")]
	else:
		hint_label.text = "%s %s" % [btn, tr("hud.hint.continue")]
