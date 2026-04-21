extends CharacterBody2D

const SPEED := 80.0
const AGGRO_RANGE := 300.0
const DIFFICULTY := {
	"normal": { "shoot_range": 128.0, "shoot_cooldown": 1.8 },
	"hard":   { "shoot_range": 256.0, "shoot_cooldown": 0.9 },
}
const OFF_SCREEN_MARGIN := 64.0
const STEP_DISTANCE := 28.0
const SCAN_SPEED := 1.0
const SCAN_SWEEP := 2.2
const BURST_MIN := 2
const BURST_MAX := 4

signal enemy_died
signal aggro_started
signal aggro_ended

@export var corpse_scene: PackedScene
@export var enemy_bullet_scene: PackedScene
@export var blood_splatter_scene: PackedScene
@export var blood_spray_scene: PackedScene
@export var casing_scene: PackedScene
@export var is_idle: bool = false

var direction := Vector2.ZERO
var player_ref: CharacterBody2D = null
var shoot_timer := 0.0
var _in_aggro := false
var _is_shooting := false
var _burst_remaining := 0
var _step_accum := 0.0
var _next_leg_frame := 1
var _scan_dir := 1.0
var _scan_accum := 0.0
var _on_screen := true

@onready var muzzle := $Muzzle
@onready var anim_sprite: AnimatedSprite2D = $FacingSprite
@onready var legs_sprite: Sprite2D = $LegsSprite
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	add_to_group("enemies")
	$WanderTimer.timeout.connect(_pick_direction)
	var notifier: VisibleOnScreenNotifier2D = $ActivationNotifier
	notifier.screen_entered.connect(_on_screen_entered)
	notifier.screen_exited.connect(_on_screen_exited)
	if is_idle:
		$WanderTimer.stop()
	else:
		_pick_direction()


func _on_screen_entered() -> void:
	_on_screen = true


func _on_screen_exited() -> void:
	_on_screen = false


func _physics_process(delta: float) -> void:
	if not _on_screen:
		return
	if _is_shooting:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_legs(delta)
		return

	if _can_see_player():
		if not _in_aggro:
			_in_aggro = true
			shoot_timer = 0.0
			emit_signal("aggro_started")
			if is_idle:
				is_idle = false
				$WanderTimer.start()

		var to_player := player_ref.global_position - global_position
		var dist := to_player.length()
		rotation = to_player.angle()
		shoot_timer += delta

		var diff: Dictionary = DIFFICULTY.get(Settings.difficulty, DIFFICULTY["normal"])
		var shoot_range: float = diff["shoot_range"]
		if dist > shoot_range:
			nav_agent.target_position = player_ref.global_position
			var nav_dir := nav_agent.get_next_path_position() - global_position
			direction = nav_dir.normalized() if nav_dir.length() > 1.0 else to_player.normalized()
		else:
			direction = Vector2.ZERO
			if shoot_timer >= diff["shoot_cooldown"]:
				shoot_timer = 0.0
				_fire_at_player()
	else:
		if _in_aggro:
			_in_aggro = false
			emit_signal("aggro_ended")
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


func _can_see_player() -> bool:
	if player_ref == null or player_ref.is_dead:
		return false
	var canvas_pos: Vector2 = get_viewport().get_canvas_transform() * global_position
	if not get_viewport().get_visible_rect().grow(OFF_SCREEN_MARGIN).has_point(canvas_pos):
		return false
	if global_position.distance_to(player_ref.global_position) > AGGRO_RANGE:
		return false
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		player_ref.global_position,
		1,
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
		_spawn_casing()


func _spawn_casing() -> void:
	if casing_scene == null:
		return
	var casing := casing_scene.instantiate()
	casing.global_position = muzzle.global_position
	casing.rotation = rotation
	var side := Vector2.UP.rotated(rotation)
	var vel := side * randf_range(10.0, 20.0) + Vector2.LEFT.rotated(rotation) * randf_range(3.0, 8.0)
	var spin := randf_range(8.0, 14.0)
	get_tree().current_scene.add_child(casing)
	casing.launch(vel, spin)


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


func _pick_direction() -> void:
	var angle := randf() * TAU
	direction = Vector2.RIGHT.rotated(angle)
	$WanderTimer.wait_time = randf_range(1.0, 2.5)


func die(impulse: Vector2 = Vector2.ZERO) -> void:
	if _in_aggro:
		_in_aggro = false
		emit_signal("aggro_ended")
	if blood_spray_scene != null:
		var spray := blood_spray_scene.instantiate()
		spray.global_position = global_position
		if impulse.length() > 0.001:
			spray.direction = impulse.normalized()
		get_parent().add_child(spray)
	if corpse_scene != null:
		var corpse := corpse_scene.instantiate()
		corpse.global_position = global_position
		corpse.add_to_group("corpse")
		get_parent().add_child(corpse)
		corpse.setup(impulse, blood_splatter_scene)
	emit_signal("enemy_died")
	queue_free()
