extends CharacterBody2D

const SPEED := 220.0
const AIM_DEADZONE := 0.2
const STEP_DISTANCE := 36.0

signal player_died

@export var bullet_scene: PackedScene

@onready var facing_sprite: Sprite2D = $FacingSprite
@onready var legs_sprite: Sprite2D = $LegsSprite

var next_pistol := 0
var next_foot_frame := 1
var step_accum := 0.0

var is_dead := false
var mop_mode := false
var carrying_corpse: Node2D = null


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if carrying_corpse != null:
		carrying_corpse.global_position = global_position + Vector2(0, -32)

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

	if not mop_mode and carrying_corpse == null and Input.is_action_pressed("shoot") and $ShootCooldown.is_stopped():
		_shoot()


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event.is_action_pressed("interact"):
		try_interact()
	if event.is_action_pressed("toggle_mop") and carrying_corpse == null:
		toggle_mop_mode()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	drop_corpse()
	emit_signal("player_died")
	# TODO: заглушка — добавить анимацию смерти, когда будет спрайт


func toggle_mop_mode() -> void:
	mop_mode = not mop_mode
	# TODO: заглушка — сменить спрайт рук на швабру/пистолет
	var managers := get_tree().get_nodes_in_group("level_manager")
	if managers.size() > 0:
		managers[0].notify_mode_changed(mop_mode)


func try_interact() -> void:
	if carrying_corpse != null:
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
	if corpse.has_node("PickupArea"):
		corpse.get_node("PickupArea").monitoring = false
		corpse.get_node("PickupArea").monitorable = false


func drop_corpse() -> void:
	if carrying_corpse == null:
		return
	if carrying_corpse.has_node("PickupArea"):
		carrying_corpse.get_node("PickupArea").monitoring = true
		carrying_corpse.get_node("PickupArea").monitorable = true
	carrying_corpse = null


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
