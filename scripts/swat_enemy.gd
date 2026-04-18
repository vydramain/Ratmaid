extends CharacterBody2D

const SPEED := 120.0

var player_ref: CharacterBody2D = null


func _ready() -> void:
	# layer 6 (bitmask 32) = swat; mask: walls (1) + player (2) = 3
	# Пули игрока (layer 4, bitmask 8) НЕ входят в маску — они проходят сквозь
	collision_layer = 32
	collision_mask = 3
	add_to_group("swat")
	$KillArea.body_entered.connect(_on_kill_area_body_entered)


func _physics_process(_delta: float) -> void:
	if player_ref == null or player_ref.is_dead:
		return
	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * SPEED
	move_and_slide()


func _on_kill_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()
