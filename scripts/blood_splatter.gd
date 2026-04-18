extends Area2D

signal cleaned


func _ready() -> void:
	# layer 7 (bitmask 64) = blood; mask: player (2)
	collision_layer = 64
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.mop_mode:
		clean()


func clean() -> void:
	set_deferred("monitoring", false)
	visible = false
	emit_signal("cleaned")
	queue_free()
