extends CharacterBody2D

const MIN_DISTANCE_LENGTH := 48.0
const MAX_PULL_SPEED := 260.0

var hitched_to : Node2D  = null
var front_direction : Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("trash_block")

func hitch(player: Node2D) -> void:
	hitched_to = player
	var player_local := player.to_local(global_position)
	front_direction = Vector2.RIGHT if player_local.x >= 0 else Vector2.LEFT

func unhitch() -> void:
	hitched_to = null
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if hitched_to == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var to_player := hitched_to.global_position - (global_position + front_direction)
	var distance := to_player.length()
	if distance <= MIN_DISTANCE_LENGTH:
		velocity = Vector2.ZERO
	else:
		var direction := to_player / distance
		var slack := distance - MIN_DISTANCE_LENGTH
		var desired_speed := slack / delta
		velocity = direction * min(desired_speed, MAX_PULL_SPEED)
	
	move_and_slide()
