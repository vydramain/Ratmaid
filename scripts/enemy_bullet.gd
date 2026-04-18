extends Area2D

const SPEED := 700.0

var direction := Vector2.ZERO


func _ready() -> void:
	# layer 5 (bitmask 16) = enemy_bullets; mask: walls (1) + player (2) = 3
	collision_layer = 16
	collision_mask = 3
	$Lifetime.start()
	$Lifetime.timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
	queue_free()
