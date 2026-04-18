extends CharacterBody2D

const SPEED := 220.0
const AIM_DEADZONE := 0.2
const STEP_DISTANCE := 36.0

@export var bullet_scene: PackedScene

@onready var facing_sprite: Sprite2D = $FacingSprite
@onready var legs_sprite: Sprite2D = $LegsSprite

var next_pistol := 0
var next_foot_frame := 1
var step_accum := 0.0


func _physics_process(delta: float) -> void:
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = move_input * SPEED
	move_and_slide()

	var aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim.length() < AIM_DEADZONE:
		aim = get_global_mouse_position() - global_position
	if aim.length() > 0.001:
		rotation = aim.angle()

	_update_hands()
	_update_legs(delta)

	if Input.is_action_pressed("shoot") and $ShootCooldown.is_stopped():
		_shoot()


func _update_hands() -> void:
	if $ShootCooldown.is_stopped():
		facing_sprite.frame = 0


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
	var muzzle: Node2D = $MuzzleLeft if next_pistol == 0 else $MuzzleRight
	var bullet := bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = rotation
	get_tree().current_scene.add_child(bullet)
	facing_sprite.frame = 3 if next_pistol == 0 else 1
	next_pistol = 1 - next_pistol
	$ShootCooldown.start()
