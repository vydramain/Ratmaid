extends CharacterBody2D

const SPEED := 80.0
const AGGRO_RANGE := 300.0
const SHOOT_COOLDOWN := 2.0
const STEP_DISTANCE := 28.0
const SCAN_SPEED := 1.0   # рад/с для осмотра в режиме idle
const SCAN_SWEEP := 2.2   # угол поворота до смены направления (рад)
const SIDESTEP_TIME := 0.35
const SIDESTEP_ANGLE := PI / 3.0

signal enemy_died
signal aggro_started
signal aggro_ended

@export var corpse_scene: PackedScene
@export var enemy_bullet_scene: PackedScene
@export var blood_splatter_scene: PackedScene
@export var is_idle: bool = false  # стоит на месте, крутит головой

var direction := Vector2.ZERO
var player_ref: CharacterBody2D = null
var shoot_timer := 0.0
var _in_aggro := false
var _is_shooting := false
var _step_accum := 0.0
var _next_leg_frame := 1
var _scan_dir := 1.0
var _scan_accum := 0.0
var _sidestep_dir := Vector2.ZERO
var _sidestep_timer := 0.0

@onready var muzzle := $Muzzle
@onready var anim_sprite: AnimatedSprite2D = $FacingSprite
@onready var legs_sprite: Sprite2D = $LegsSprite


func _ready() -> void:
	add_to_group("enemies")
	$WanderTimer.timeout.connect(_pick_direction)
	if is_idle:
		$WanderTimer.stop()
	else:
		_pick_direction()


func _physics_process(delta: float) -> void:
	if _is_shooting:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_legs(delta)
		return

	if _can_see_player():
		if not _in_aggro:
			_in_aggro = true
			emit_signal("aggro_started")
			# Idle-враг после первого обнаружения становится полноценным преследователем
			if is_idle:
				is_idle = false
				$WanderTimer.start()
		var to_player := (player_ref.global_position - global_position).normalized()
		rotation = to_player.angle()
		if _sidestep_timer > 0.0:
			_sidestep_timer -= delta
			direction = _sidestep_dir
		else:
			direction = to_player
		shoot_timer += delta
		if shoot_timer >= SHOOT_COOLDOWN:
			shoot_timer = 0.0
			_fire_at_player()
	else:
		if _in_aggro:
			_in_aggro = false
			emit_signal("aggro_ended")
			_sidestep_timer = 0.0
			_pick_direction()

		if is_idle:
			_do_scan(delta)
			velocity = Vector2.ZERO
			move_and_slide()
			_update_legs(delta)
			return

	velocity = direction * SPEED
	move_and_slide()
	_update_legs(delta)
	if get_slide_collision_count() > 0:
		if _in_aggro:
			_start_sidestep()
		else:
			_pick_direction()


func _start_sidestep() -> void:
	var to_player := (player_ref.global_position - global_position).normalized()
	var normal := get_slide_collision(0).get_normal()
	var side := signf(to_player.cross(normal))
	if side == 0.0:
		side = 1.0
	_sidestep_dir = to_player.rotated(side * SIDESTEP_ANGLE)
	_sidestep_timer = SIDESTEP_TIME


func _can_see_player() -> bool:
	if player_ref == null or player_ref.is_dead:
		return false
	if global_position.distance_to(player_ref.global_position) > AGGRO_RANGE:
		return false
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		player_ref.global_position,
		1,        # маска: только стены (layer 1)
		[get_rid()]
	)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _do_scan(delta: float) -> void:
	var step := SCAN_SPEED * _scan_dir * delta
	rotation += step
	_scan_accum += absf(step)
	if _scan_accum >= SCAN_SWEEP:
		_scan_accum = 0.0
		_scan_dir *= -1.0


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
