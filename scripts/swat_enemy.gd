extends CharacterBody2D

const SPEED := 120.0
const STEP_DISTANCE := 28.0
const SHOOT_COOLDOWN := 1.0
const SHOOT_RANGE_NORMAL := 128.0
const SHOOT_RANGE_HARD := 256.0
const BURST_MIN := 2
const BURST_MAX := 4

var player_ref: CharacterBody2D = null
var _step_accum := 0.0
var _next_leg_frame := 1
var _shoot_timer := 0.0
var _is_shooting := false
var _burst_remaining := 0
var _on_screen := true

@export var enemy_bullet_scene: PackedScene

@onready var legs_sprite: Sprite2D = $LegsSprite
@onready var anim_sprite: AnimatedSprite2D = $FacingSprite
@onready var muzzle: Marker2D = $Muzzle
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	# layer 6 (bitmask 32) = swat; mask: walls (1) + player (2) + furniture (128) = 131
	# Пули игрока (bitmask 8) НЕ входят в маску — отлетают
	collision_layer = 32
	collision_mask = 131
	add_to_group("swat")
	var notifier: VisibleOnScreenNotifier2D = $ActivationNotifier
	notifier.screen_entered.connect(func() -> void: _on_screen = true)
	notifier.screen_exited.connect(func() -> void: _on_screen = false)


func _physics_process(delta: float) -> void:
	if not _on_screen:
		return
	if player_ref == null or player_ref.is_dead:
		return

	if _is_shooting:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_legs(delta)
		return

	var to_player := player_ref.global_position - global_position
	var dist := to_player.length()
	rotation = to_player.angle()
	_shoot_timer += delta

	var shoot_range := SHOOT_RANGE_HARD if Settings.difficulty == "hard" else SHOOT_RANGE_NORMAL
	if dist > shoot_range:
		nav_agent.target_position = player_ref.global_position
		var nav_dir := nav_agent.get_next_path_position() - global_position
		velocity = (nav_dir.normalized() if nav_dir.length() > 1.0 else to_player.normalized()) * SPEED
	else:
		velocity = Vector2.ZERO
		if _shoot_timer >= SHOOT_COOLDOWN:
			_shoot_timer = 0.0
			_fire_at_player()

	move_and_slide()
	_update_legs(delta)


func _fire_at_player() -> void:
	if enemy_bullet_scene == null or _is_shooting:
		return
	_burst_remaining = randi_range(BURST_MIN, BURST_MAX) - 1
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
	if _burst_remaining > 0:
		_burst_remaining -= 1
		anim_sprite.play("guns_action")
		anim_sprite.frame_changed.connect(_on_guns_frame_changed)
		anim_sprite.animation_finished.connect(_on_guns_finished, CONNECT_ONE_SHOT)
	else:
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
