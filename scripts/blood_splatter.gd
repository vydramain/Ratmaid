extends Area2D

signal cleaned

@export var max_radius: float = 24.0
@export var grow_delay: float = 0.0

var _radius := 0.0
var _delay_elapsed := 0.0
const GROW_SPEED := 16.0


func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	z_index = 1
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	$CollisionShape2D.shape.radius = max_radius
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _radius >= max_radius:
		set_process(false)
		return
	if _delay_elapsed < grow_delay:
		_delay_elapsed += delta
		return
	_radius = minf(_radius + GROW_SPEED * delta, max_radius)
	queue_redraw()


func _draw() -> void:
	if _radius > 0.0:
		draw_circle(Vector2.ZERO, _radius, Color(0.52, 0.0, 0.0, 0.82))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.mop_mode:
		clean()


func clean() -> void:
	set_deferred("monitoring", false)
	emit_signal("cleaned")
	queue_free()
