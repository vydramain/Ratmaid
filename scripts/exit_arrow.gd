extends Node2D

## UI-стрелка, которая указывает игроку на зону выхода в фазе CLEANUP.
## Всегда на экране: если выход виден — сидит на его краю со стороны игрока;
## если выхода нет в кадре — залипает на границе видимой области камеры
## на луче «игрок → выход». Слегка качается вдоль направления.

@export var margin: float = 24.0
@export var wobble_amp: float = 4.0
@export var wobble_freq: float = 5.0

@onready var sprite: Sprite2D = $Sprite2D

var exit: Area2D = null
var _time := 0.0
var _player: Node2D = null


func _ready() -> void:
	visible = false
	set_process(false)


func activate(exit_area: Area2D) -> void:
	exit = exit_area
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
	visible = true
	set_process(true)


func _process(delta: float) -> void:
	if exit == null or _player == null:
		return
	_time += delta

	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var cam_center := cam.get_screen_center_position()
	var viewport_size: Vector2 = get_viewport_rect().size / cam.zoom
	var view_rect := Rect2(cam_center - viewport_size * 0.5, viewport_size)
	var bounded := view_rect.grow(-margin)

	var exit_rect := _get_exit_rect()
	var player_pos := _player.global_position

	var base_pos: Vector2
	if bounded.intersects(exit_rect):
		# Выход в кадре — садимся на ближайшую к игроку точку коллайдера и чуть наружу
		var edge := Vector2(
			clampf(player_pos.x, exit_rect.position.x, exit_rect.end.x),
			clampf(player_pos.y, exit_rect.position.y, exit_rect.end.y)
		)
		var away := player_pos - exit_rect.get_center()
		if away.length() > 0.001:
			base_pos = edge + away.normalized() * margin
		else:
			base_pos = edge
	else:
		# Выход за кадром — пересечение луча игрок→выход с видимой областью
		base_pos = _ray_rect_exit(player_pos, exit_rect.get_center(), bounded)

	var to_exit := exit_rect.get_center() - base_pos
	var direction := to_exit.normalized() if to_exit.length() > 0.001 else Vector2.RIGHT

	var wobble := direction * sin(_time * wobble_freq) * wobble_amp
	global_position = base_pos + wobble
	sprite.frame = _cardinal_frame(direction)


func _get_exit_rect() -> Rect2:
	var shape_node: CollisionShape2D = null
	for child in exit.get_children():
		if child is CollisionShape2D:
			shape_node = child
			break
	if shape_node == null:
		return Rect2(exit.global_position, Vector2.ZERO)
	var shape := shape_node.shape
	if shape is RectangleShape2D:
		var size: Vector2 = (shape as RectangleShape2D).size
		return Rect2(shape_node.global_position - size * 0.5, size)
	if shape is CircleShape2D:
		var r: float = (shape as CircleShape2D).radius
		return Rect2(shape_node.global_position - Vector2(r, r), Vector2(r * 2.0, r * 2.0))
	return Rect2(exit.global_position, Vector2.ZERO)


## Возвращает точку выхода луча (from → to) из прямоугольника rect.
## Предполагается, что from находится внутри rect (игрок в кадре).
func _ray_rect_exit(from: Vector2, to: Vector2, rect: Rect2) -> Vector2:
	var dir := to - from
	var length := dir.length()
	if length < 0.001:
		return rect.get_center()
	dir /= length
	var t_max := length
	if absf(dir.x) > 1e-6:
		var tx1 := (rect.position.x - from.x) / dir.x
		var tx2 := (rect.end.x - from.x) / dir.x
		t_max = minf(t_max, maxf(tx1, tx2))
	if absf(dir.y) > 1e-6:
		var ty1 := (rect.position.y - from.y) / dir.y
		var ty2 := (rect.end.y - from.y) / dir.y
		t_max = minf(t_max, maxf(ty1, ty2))
	return from + dir * maxf(t_max, 0.0)


## 0=вправо, 1=вверх, 2=влево, 3=вниз (кадры в спрайте именно в таком порядке).
func _cardinal_frame(direction: Vector2) -> int:
	var angle := direction.angle()
	if angle >= -PI * 0.25 and angle <= PI * 0.25:
		return 0
	if angle > PI * 0.25 and angle < PI * 0.75:
		return 3
	if angle < -PI * 0.25 and angle > -PI * 0.75:
		return 1
	return 2
