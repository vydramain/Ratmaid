extends CharacterBody2D

const INITIAL_SPEED := 160.0
const FRICTION := 280.0

var _blood_scene: PackedScene = null
var _slide_velocity := Vector2.ZERO
var _stopped := false


func _ready() -> void:
	add_to_group("corpse")


func setup(impulse: Vector2, blood_scene: PackedScene) -> void:
	_blood_scene = blood_scene
	if impulse.length() > 0.001:
		_slide_velocity = impulse.normalized() * INITIAL_SPEED
		rotation = impulse.angle() + PI / 2.0


func _physics_process(delta: float) -> void:
	if _stopped:
		return
	if _slide_velocity.length() < 4.0:
		_slide_velocity = Vector2.ZERO
		_stopped = true
		_spawn_blood()
		return
	_slide_velocity = _slide_velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	velocity = _slide_velocity
	move_and_slide()


func _spawn_blood() -> void:
	if _blood_scene == null:
		return
	var managers := get_tree().get_nodes_in_group("level_manager")
	var configs: Array[Dictionary] = [
		{"offset": Vector2.ZERO,    "radius": 26.0, "delay": 0.0},
		{"offset": Vector2(10, -6), "radius": 18.0, "delay": 0.2},
		{"offset": Vector2(-8, 8),  "radius": 21.0, "delay": 0.4},
	]
	for cfg in configs:
		var splatter := _blood_scene.instantiate()
		splatter.global_position = global_position + cfg["offset"]
		splatter.max_radius = cfg["radius"]
		splatter.grow_delay = cfg["delay"]
		get_parent().add_child(splatter)
		if managers.size() > 0:
			managers[0].register_blood_splatter(splatter)
