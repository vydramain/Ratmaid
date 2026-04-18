extends CanvasLayer

@onready var timer_label: Label = $TimerLabel
@onready var mode_label: Label = $ModeLabel
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/VBox/ResultLabel
@onready var result_hint: Label = $ResultPanel/VBox/HintLabel
@onready var hints_bar: Label = $HintsBar

var _showing_result := false
var _active_hints: Array = []   # [["action", "описание"], ...]


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
	var total: int = int(seconds)
	var mins: int = total / 60
	var secs: int = total % 60
	timer_label.text = "%d:%02d" % [mins, secs]


func hide_timer() -> void:
	timer_label.visible = false


func show_mode(is_mop: bool) -> void:
	mode_label.visible = true
	mode_label.text = "[ ШВАБРА ]" if is_mop else "[ ПИСТОЛЕТЫ ]"


## Устанавливает подсказки внизу экрана.
## hints — массив пар: [["action_name", "описание"], ...]
## Пример: [["interact", "Взять труп"], ["toggle_mop", "Швабра"]]
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
		var desc: String   = pair[1]
		parts.append("%s %s" % [InputDevice.get_hint_text(action), desc])
	hints_bar.text = "   ".join(parts)
	hints_bar.visible = true
	# Обновить кнопку на экране результата, если он показан
	if _showing_result:
		result_hint.text = "%s Вернуться в меню" % InputDevice.get_hint_text("ui_accept")


func show_gameover(reason: String) -> void:
	_showing_result = true
	result_panel.visible = true
	match reason:
		"combat":
			result_label.text = "ВЫ УБИТЫ"
		"exit_early":
			result_label.text = "Полицейские нашли улики и арестовали тебя."
		"timer":
			result_label.text = "Спецназ окружил здание. Тебя убили при задержании."
		_:
			result_label.text = "GAME OVER"
	result_hint.text = "%s Вернуться в меню" % InputDevice.get_hint_text("ui_accept")


func show_victory() -> void:
	_showing_result = true
	result_panel.visible = true
	result_label.text = "МИССИЯ ВЫПОЛНЕНА\n\nАгент докладывает: задание выполнено. Улики уничтожены.\nТеррористический сигнал нейтрализован."
	result_hint.text = "%s Вернуться в меню" % InputDevice.get_hint_text("ui_accept")


func _unhandled_input(event: InputEvent) -> void:
	if _showing_result and event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
