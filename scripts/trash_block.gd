extends CharacterBody2D

const MIN_DISTANCE_LENGTH := 32.0
const MAX_PULL_SPEED := 260.0

var hitched_to : Node2D  = null

func hitch(player: Node2D) -> void:
	hitched_to = player

func unhitch() -> void:
	hitched_to = null
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if hitched_to == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var to_player := hitched_to.global_position - global_position
	var distance := to_player.length()
	if distance <= MIN_DISTANCE_LENGTH:
		velocity = Vector2.ZERO
	else:
		var direction := to_player / distance
		var slack := distance - MIN_DISTANCE_LENGTH
		var desired_speed := slack / delta
		velocity = direction * min(desired_speed, MAX_PULL_SPEED)
	
	move_and_slide()
