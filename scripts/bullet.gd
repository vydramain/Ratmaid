extends Area2D

const SPEED := 900.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Lifetime.timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * SPEED * delta


func _on_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()
	queue_free()
