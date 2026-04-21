extends Sprite2D

const MAX_GAMEPAD_DIST := 25.0
const GAMEPAD_HIDE_THRESHOLD := 0.15


func _ready() -> void:
	texture = preload("res://images/ui_cross.png")
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = preload("res://shaders/crosshair_invert.gdshader")
	material = shader_mat


func _process(_delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		visible = false
		return

	if InputDevice.is_gamepad():
		_update_gamepad(players[0] as Node2D)
	else:
		_update_mouse()


func _update_mouse() -> void:
	visible = true
	position = get_viewport().get_mouse_position()


func _update_gamepad(player: Node2D) -> void:
	var aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim.length() < GAMEPAD_HIDE_THRESHOLD:
		visible = false
		return
	visible = true
	var player_screen: Vector2 = get_viewport().get_canvas_transform() * player.global_position
	position = player_screen + aim.normalized() * minf(aim.length(), 1.0) * MAX_GAMEPAD_DIST
