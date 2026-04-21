extends CharacterBody2D

const SPEED := 220.0
const AIM_DEADZONE := 0.2
const STEP_DISTANCE := 36.0

signal player_died

@export var bullet_scene: PackedScene
@export var casing_scene: PackedScene
@export var blood_spray_scene: PackedScene
@export var blood_splatter_scene: PackedScene

@onready var facing_sprite: AnimatedSprite2D = $FacingSprite
@onready var legs_sprite: Sprite2D = $LegsSprite

var next_pistol := 0
var next_foot_frame := 1
var step_accum := 0.0

var is_dead := false
var mop_mode := false
var carrying_corpse: Node2D = null
var input_locked := false
var _weapons_locked := false


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if carrying_corpse != null:
		carrying_corpse.global_position = global_position + Vector2(0, -32)

	if input_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = move_input * SPEED
	move_and_slide()

	var aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim.length() >= AIM_DEADZONE:
		rotation = aim.angle()
	elif not InputDevice.is_gamepad():
		var mouse_aim := get_global_mouse_position() - global_position
		if mouse_aim.length() > 0.001:
			rotation = mouse_aim.angle()

	_update_legs(delta)

	if not mop_mode and not _weapons_locked and carrying_corpse == null and Input.is_action_pressed("shoot") and $ShootCooldown.is_stopped():
		_shoot()


func _unhandled_input(event: InputEvent) -> void:
	if is_dead or input_locked:
		return
	if event.is_action_pressed("interact"):
		try_interact()
	if event.is_action_pressed("toggle_mop") and carrying_corpse == null and not _weapons_locked:
		toggle_mop_mode()


func die(impulse: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	is_dead = true
	drop_corpse()
	_spawn_death_blood(impulse)
	emit_signal("player_died")
	# TODO: заглушка — добавить анимацию смерти, когда будет спрайт


func _spawn_death_blood(impulse: Vector2) -> void:
	if blood_spray_scene != null:
		var spray := blood_spray_scene.instantiate()
		spray.global_position = global_position
		if impulse.length() > 0.001:
			spray.direction = impulse.normalized()
		get_tree().current_scene.add_child(spray)
	if blood_splatter_scene != null:
		var configs: Array[Dictionary] = [
			{"offset": Vector2.ZERO,    "radius": 26.0, "delay": 0.0},
			{"offset": Vector2(10, -6), "radius": 18.0, "delay": 0.2},
			{"offset": Vector2(-8, 8),  "radius": 21.0, "delay": 0.4},
		]
		for cfg in configs:
			var splatter := blood_splatter_scene.instantiate()
			splatter.global_position = global_position + cfg["offset"]
			splatter.max_radius = cfg["radius"]
			splatter.grow_delay = cfg["delay"]
			get_tree().current_scene.add_child(splatter)


func toggle_mop_mode() -> void:
	_weapons_locked = true
	if not mop_mode:
		facing_sprite.play("guns_hide")
		facing_sprite.animation_finished.connect(_on_guns_hidden, CONNECT_ONE_SHOT)
	else:
		facing_sprite.play("mop_hide")
		facing_sprite.animation_finished.connect(_on_mop_hidden, CONNECT_ONE_SHOT)


func _on_guns_hidden() -> void:
	facing_sprite.play_backwards("mop_hide")
	facing_sprite.animation_finished.connect(_on_mop_drawn, CONNECT_ONE_SHOT)


func _on_mop_drawn() -> void:
	mop_mode = true
	_weapons_locked = false
	facing_sprite.play("mop_action")
	var managers := get_tree().get_nodes_in_group("level_manager")
	if managers.size() > 0:
		managers[0].notify_mode_changed(mop_mode)


func _on_mop_hidden() -> void:
	facing_sprite.play_backwards("guns_hide")
	facing_sprite.animation_finished.connect(_on_guns_drawn, CONNECT_ONE_SHOT)


func _on_guns_drawn() -> void:
	mop_mode = false
	_weapons_locked = false
	facing_sprite.stop()
	var managers := get_tree().get_nodes_in_group("level_manager")
	if managers.size() > 0:
		managers[0].notify_mode_changed(mop_mode)


func try_interact() -> void:
	if carrying_corpse != null:
		drop_corpse()
		return
	# Corpse.PickupArea — это Area2D на layer 4; InteractionArea имеет mask 4
	var area: Area2D = $InteractionArea
	for overlap in area.get_overlapping_areas():
		var parent := overlap.get_parent()
		if parent.is_in_group("corpse"):
			pickup_corpse(parent)
			return


func pickup_corpse(corpse: Node2D) -> void:
	carrying_corpse = corpse


func drop_corpse() -> void:
	carrying_corpse = null


func _update_legs(delta: float) -> void:
	var speed := velocity.length()
	if speed < 1.0:
		legs_sprite.frame = 0
		step_accum = 0.0
		return
	step_accum += speed * delta
	if step_accum >= STEP_DISTANCE:
		step_accum -= STEP_DISTANCE
		legs_sprite.frame = next_foot_frame
		next_foot_frame = 3 if next_foot_frame == 1 else 1


func _shoot() -> void:
	if bullet_scene == null:
		return
	var is_left := next_pistol == 0
	var muzzle: Node2D = $MuzzleLeft if is_left else $MuzzleRight
	var bullet := bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = rotation
	get_tree().current_scene.add_child(bullet)
	_spawn_casing(muzzle, is_left)
	next_pistol = 1 - next_pistol
	$ShootCooldown.start()
	facing_sprite.play("guns_action")
	facing_sprite.animation_finished.connect(facing_sprite.stop, CONNECT_ONE_SHOT)


func _spawn_casing(muzzle: Node2D, is_left: bool) -> void:
	if casing_scene == null:
		return
	var casing := casing_scene.instantiate()
	casing.global_position = muzzle.global_position
	casing.rotation = rotation
	# Гильза вылетает перпендикулярно дулу наружу (в сторону "плеча" пистолета)
	var side := Vector2.UP.rotated(rotation) if is_left else Vector2.DOWN.rotated(rotation)
	var velocity := side * randf_range(10.0, 20.0) + Vector2.LEFT.rotated(rotation) * randf_range(3.0, 8.0)
	var spin := randf_range(8.0, 14.0) * (-1.0 if is_left else 1.0)
	get_tree().current_scene.add_child(casing)
	casing.launch(velocity, spin)
