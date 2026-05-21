extends CharacterBody2D

# Шпаргалка по математике (системы координат, векторы, lerp_angle, atan2, Тейлор):
# см. trash_block_math.md в этой же папке.

const MIN_DISTANCE_LENGTH := 48.0  # "длина верёвки" — ближе не тянем
const MAX_PULL_SPEED := 260.0      # потолок скорости подтягивания

const HITCH_OFFSET := 25.0   # отступ якоря сцепки от центра тележки
							 # ~полуширина тележки по локальной оси X
const ROT_SPEED := 8.0       # темп поворота к цели, в обратных секундах
							 # больше = быстрее доворачивается до игрока

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
	
	var anchor_local := HITCH_OFFSET * front_direction
	var anchor_world := global_position + anchor_local.rotated(rotation)
	var to_player := hitched_to.global_position - anchor_world
	var distance := to_player.length()
	
	# --- ПЛАВНЫЙ ПОВОРОТ ---
	# Хочу: чтобы вектор front_direction (в мире) смотрел на игрока.
	# Не мгновенно, а плавно — эффект "хвост доворачивается".
	#
	# Шаг 1. Куда сейчас смотрит front_direction в мире?
	#   Это угол вектора front_direction после поворота локали на rotation:
	#   текущий_мировой_угол = rotation + front_direction.angle()
	#   front_direction.angle() — константа: 0 для RIGHT, π для LEFT.
	#
	# Шаг 2. Куда хочу, чтобы front_direction смотрел?
	#   На игрока. Это направление в мире: to_player.angle().
	#
	# Шаг 3. Каким должен быть rotation, чтобы шаг 1 совпал с шагом 2?
	#   rotation + front_direction.angle() = to_player.angle()
	#   rotation_target = to_player.angle() - front_direction.angle()
	#   (Это НЕ "на сколько повернуть". Это "какое значение должно быть у поля rotation".)
	#
	# Шаг 4. Не присваивать сразу, а подвести плавно через lerp_angle.
	#   lerp_angle(a, b, t) — линейная интерполяция углов по КРАТЧАЙШЕЙ дуге.
	#   t — доля кратчайшего пути, проходимая за этот кадр.
	#   Здесь t = ROT_SPEED * delta. delta — секунды между кадрами; ROT_SPEED [1/sec]
	#   задаёт "темп". При фикс. цели остаток разности множится на (1-t) каждый кадр
	#   → экспоненциальное затухание → ease-out (быстро в начале, плавно к концу).
	#
	# TODO написать здесь:
	#   var rotation_target := to_player.angle() - front_direction.angle()
	#   rotation = lerp_angle(rotation, rotation_target, ROT_SPEED * delta)
	#
	# ВНИМАНИЕ: rotation = ..., а не rotate(...). rotate() прибавляет дельту;
	# нам нужно присвоить вычисленное значение.

	if distance <= MIN_DISTANCE_LENGTH:
		velocity = Vector2.ZERO
	else:
		var direction := to_player / distance
		var slack := distance - MIN_DISTANCE_LENGTH
		var desired_speed := slack / delta
		velocity = direction * min(desired_speed, MAX_PULL_SPEED)
	
	move_and_slide()
