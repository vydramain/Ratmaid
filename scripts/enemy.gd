extends CharacterBody2D

const SPEED := 80.0
const AGGRO_RANGE := 300.0
const SHOOT_COOLDOWN := 2.0

signal enemy_died
signal aggro_started   # враг входит в зону агро
signal aggro_ended     # враг выходит из зоны агро (или умирает)

@export var corpse_scene: PackedScene
@export var enemy_bullet_scene: PackedScene
@export var blood_splatter_scene: PackedScene

const STEP_DISTANCE := 28.0

var direction := Vector2.ZERO
var player_ref: CharacterBody2D = null
var shoot_timer := 0.0
var _in_aggro := false
var _is_shooting := false
var _step_accum := 0.0
var _next_leg_frame := 1

@onready var muzzle := $Muzzle
@onready var anim_sprite: AnimatedSprite2D = $FacingSprite
@onready var legs_sprite: Sprite2D = $LegsSprite


func _ready() -> void:
	add_to_group("enemies")
	$WanderTimer.timeout.connect(_pick_direction)
	_pick_direction()


func _physics_process(delta: float) -> void:
	if _is_shooting:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_legs(delta)
		return

	if player_ref != null and not player_ref.is_dead:
		var dist := global_position.distance_to(player_ref.global_position)
		if dist < AGGRO_RANGE:
			if not _in_aggro:
				_in_aggro = true
				emit_signal("aggro_started")
			# Преследовать игрока
			direction = (player_ref.global_position - global_position).normalized()
			_face_player()
			shoot_timer += delta
			if shoot_timer >= SHOOT_COOLDOWN:
				shoot_timer = 0.0
				_fire_at_player()
		else:
			if _in_aggro:
				_in_aggro = false
				emit_signal("aggro_ended")
	velocity = direction * SPEED
	move_and_slide()
	_update_legs(delta)
	if get_slide_collision_count() > 0 and not _in_aggro:
		_pick_direction()


func _face_player() -> void:
	rotation = (player_ref.global_position - global_position).angle()


func _fire_at_player() -> void:
	if enemy_bullet_scene == null or _is_shooting:
		return
	_is_shooting = true
	anim_sprite.play("guns_action")
	anim_sprite.frame_changed.connect(_on_guns_frame_changed)
	anim_sprite.animation_finished.connect(_on_guns_finished, CONNECT_ONE_SHOT)


func _on_guns_frame_changed() -> void:
	if anim_sprite.frame == 1:
		anim_sprite.frame_changed.disconnect(_on_guns_frame_changed)
		if enemy_bullet_scene == null or player_ref == null:
			return
		var bullet := enemy_bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.direction = (player_ref.global_position - muzzle.global_position).normalized()
		get_tree().current_scene.add_child(bullet)


func _on_guns_finished() -> void:
	_is_shooting = false
	anim_sprite.stop()
	anim_sprite.frame = 0


func _update_legs(delta: float) -> void:
	var speed := velocity.length()
	if speed < 1.0:
		legs_sprite.frame = 0
		_step_accum = 0.0
		return
	_step_accum += speed * delta
	if _step_accum >= STEP_DISTANCE:
		_step_accum -= STEP_DISTANCE
		legs_sprite.frame = _next_leg_frame
		_next_leg_frame = (_next_leg_frame % 3) + 1


func _pick_direction() -> void:
	var angle := randf() * TAU
	direction = Vector2.RIGHT.rotated(angle)
	$WanderTimer.wait_time = randf_range(1.0, 2.5)


func die(impulse: Vector2 = Vector2.ZERO) -> void:
	if _in_aggro:
		_in_aggro = false
		emit_signal("aggro_ended")
	if corpse_scene != null:
		var corpse := corpse_scene.instantiate()
		corpse.global_position = global_position
		corpse.add_to_group("corpse")
		get_parent().add_child(corpse)
		corpse.setup(impulse, blood_splatter_scene)
	emit_signal("enemy_died")
	queue_free()
