extends CharacterBody2D

# Шпаргалка по математике 
# (системы координат, векторы, lerp_angle, atan2, Тейлор):
# см. trash_block_math.md в этой же папке.

const MIN_DISTANCE_LENGTH := 32.0  # "длина верёвки" — ближе не тянем
const MAX_PULL_SPEED := 260.0      # потолок скорости подтягивания

const HITCH_OFFSET := 25.0  # отступ якоря сцепки от центра тележки полуширина 
							# тележки по локальной оси X
const ROT_SPEED := 8.0      # темп поворота к цели, в обратных секундах 
							# больше = быстрее доворачивается до игрока

var hitched_to : Node2D  = null
var front_direction : Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("trash_block")

func hitch(player: Node2D) -> void:
	hitched_to = player
	var player_local := to_local(player.global_position)
	front_direction = Vector2.RIGHT if player_local.x >= 0 else Vector2.LEFT

func unhitch() -> void:
	hitched_to = null
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if hitched_to == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var anchor_local := HITCH_OFFSET * front_direction
	var anchor_world := global_position + anchor_local.rotated(rotation)
	var to_player := hitched_to.global_position - anchor_world
	var distance := to_player.length()
	
	if distance <= MIN_DISTANCE_LENGTH:
		velocity = Vector2.ZERO
	else:
		var rotation_target = to_player.angle() - front_direction.angle()
		rotation = lerp_angle(rotation, rotation_target, ROT_SPEED * delta)
		
		var direction := to_player / distance
		var slack := distance - MIN_DISTANCE_LENGTH
		var desired_speed := slack / delta
		velocity = direction * min(desired_speed, MAX_PULL_SPEED)
	
	move_and_slide()
