extends CanvasLayer

@onready var tint: ColorRect = $Tint
@onready var bar1: ColorRect = $Bar1
@onready var bar2: ColorRect = $Bar2

var _tween: Tween = null
var _sustained_active := false


func _ready() -> void:
	tint.modulate.a = 0.0
	bar1.visible = false
	bar2.visible = false


func flash() -> void:
	_kill_tween()
	_sustained_active = false
	tint.color = Color(1.0, 0.1, 0.5, 1.0)
	bar1.visible = true
	bar2.visible = true
	bar1.position.y = randf_range(0.0, get_viewport().get_visible_rect().size.y)
	bar2.position.y = randf_range(0.0, get_viewport().get_visible_rect().size.y)
	_tween = create_tween().set_parallel(false)
	_tween.tween_property(tint, "modulate:a", 0.7, 0.05)
	_tween.tween_property(tint, "modulate:a", 0.1, 0.08)
	_tween.tween_property(tint, "modulate:a", 0.6, 0.06)
	_tween.tween_property(tint, "modulate:a", 0.0, 0.20)
	_tween.tween_callback(_on_flash_done)


func _on_flash_done() -> void:
	bar1.visible = false
	bar2.visible = false


func start_sustained() -> void:
	_kill_tween()
	_sustained_active = true
	tint.color = Color(0.6, 0.0, 0.4, 1.0)
	bar1.visible = true
	bar2.visible = true
	_run_sustained_step()


func stop_sustained() -> void:
	_sustained_active = false
	_kill_tween()
	bar1.visible = false
	bar2.visible = false
	_tween = create_tween()
	_tween.tween_property(tint, "modulate:a", 0.0, 0.4)


func _run_sustained_step() -> void:
	if not _sustained_active:
		return
	var screen_h := get_viewport().get_visible_rect().size.y
	bar1.position.y = randf_range(0.0, screen_h)
	bar2.position.y = randf_range(0.0, screen_h)
	var target_a := randf_range(0.08, 0.28)
	var dur := randf_range(0.08, 0.18)
	_tween = create_tween()
	_tween.tween_property(tint, "modulate:a", target_a, dur)
	_tween.tween_callback(_run_sustained_step)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
