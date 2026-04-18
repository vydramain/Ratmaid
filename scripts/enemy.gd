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

var direction := Vector2.ZERO
var player_ref: CharacterBody2D = null
var shoot_timer := 0.0
var _in_aggro := false

@onready var muzzle := $Muzzle


func _ready() -> void:
	add_to_group("enemies")
	$WanderTimer.timeout.connect(_pick_direction)
	_pick_direction()


func _physics_process(delta: float) -> void:
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
	if get_slide_collision_count() > 0 and not _in_aggro:
		_pick_direction()


func _face_player() -> void:
	rotation = (player_ref.global_position - global_position).angle()


func _fire_at_player() -> void:
	if enemy_bullet_scene == null:
		return
	var bullet := enemy_bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.direction = (player_ref.global_position - muzzle.global_position).normalized()
	get_tree().current_scene.add_child(bullet)


func _pick_direction() -> void:
	var angle := randf() * TAU
	direction = Vector2.RIGHT.rotated(angle)
	$WanderTimer.wait_time = randf_range(1.0, 2.5)


func die() -> void:
	if _in_aggro:
		_in_aggro = false
		emit_signal("aggro_ended")
	if blood_splatter_scene != null:
		var splatter := blood_splatter_scene.instantiate()
		splatter.global_position = global_position
		get_parent().add_child(splatter)
		var managers := get_tree().get_nodes_in_group("level_manager")
		if managers.size() > 0:
			managers[0].register_blood_splatter(splatter)
	if corpse_scene != null:
		var corpse := corpse_scene.instantiate()
		corpse.global_position = global_position
		corpse.add_to_group("corpse")
		get_parent().add_child(corpse)
	emit_signal("enemy_died")
	queue_free()
