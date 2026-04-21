extends RigidBody2D

## Shell casing. Flies with a small impulse, spins, then freezes until mopped up.
## If counts_toward_cleanup is true it registers with LevelManager and is
## required for a clean exit on HARD difficulty.

signal cleaned

const REST_SPEED := 6.0
const REST_SPIN := 0.3

@export var counts_toward_cleanup: bool = true

var _cleanup_area: Area2D


func _ready() -> void:
	add_to_group("casings")
	_cleanup_area = $CleanupArea
	_cleanup_area.body_entered.connect(_on_player_entered)
	if counts_toward_cleanup:
		var mgrs := get_tree().get_nodes_in_group("level_manager")
		if mgrs.size() > 0:
			mgrs[0].register_casing(self)


func _physics_process(_delta: float) -> void:
	if freeze:
		return
	if linear_velocity.length() < REST_SPEED and absf(angular_velocity) < REST_SPIN:
		freeze = true


## Launch the casing: `velocity` is the initial linear velocity, `spin` is angular velocity (rad/s).
func launch(velocity: Vector2, spin: float) -> void:
	linear_velocity = velocity
	angular_velocity = spin


func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.mop_mode:
		emit_signal("cleaned")
		queue_free()
