extends CharacterBody2D

const SPEED := 80.0

@export var corpse_scene: PackedScene

var direction := Vector2.ZERO


func _ready() -> void:
	$WanderTimer.timeout.connect(_pick_direction)
	_pick_direction()


func _physics_process(_delta: float) -> void:
	velocity = direction * SPEED
	move_and_slide()
	if get_slide_collision_count() > 0:
		_pick_direction()


func _pick_direction() -> void:
	var angle := randf() * TAU
	direction = Vector2.RIGHT.rotated(angle)
	$WanderTimer.wait_time = randf_range(1.0, 2.5)


func die() -> void:
	if corpse_scene != null:
		var corpse := corpse_scene.instantiate()
		corpse.global_position = global_position
		get_parent().add_child(corpse)
	queue_free()
