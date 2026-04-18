extends CanvasLayer

signal dialogue_finished

const TYPEWRITER_SPEED := 0.03  # секунд на символ

const LINES: Array[String] = [
	"[Радиоперехват] Поступил СИГНАЛ о том, что в придорожном кафе произошла перестрелка. Есть пострадавшие. Всем свободным отрядам спецназа срочно отправиться на место происшествия.",
	"[Агент] Чёрт, надо срочно УБИРАТЬСЯ."
]

var _current_line := 0
var _char_index := 0
var _timer := 0.0
var _is_animating := false

@onready var text_label: RichTextLabel = $Panel/VBox/TextLabel
@onready var hint_label: Label = $Panel/VBox/HintLabel


func _ready() -> void:
	visible = false
	InputDevice.device_changed.connect(_refresh_hints)


func start_dialogue() -> void:
	_current_line = 0
	visible = true
	_show_line(_current_line)


func _show_line(_index: int) -> void:
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
		text_label.text = LINES[_current_line].substr(0, _char_index)
		if _char_index >= LINES[_current_line].length():
			_is_animating = false
			_refresh_hints()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		if _is_animating:
			text_label.text = LINES[_current_line]
			_char_index = LINES[_current_line].length()
			_is_animating = false
			_refresh_hints()
		else:
			_advance_line()
		get_viewport().set_input_as_handled()


func _advance_line() -> void:
	_current_line += 1
	if _current_line >= LINES.size():
		visible = false
		emit_signal("dialogue_finished")
	else:
		_show_line(_current_line)


func _refresh_hints() -> void:
	var btn := InputDevice.get_hint_text("ui_accept")
	if _is_animating:
		hint_label.text = "%s пропустить" % btn
	else:
		hint_label.text = "%s продолжить" % btn
