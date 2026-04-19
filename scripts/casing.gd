extends RigidBody2D

## Стреляная гильза. Летит с небольшим импульсом, крутится вокруг оси,
## останавливается и лежит до уборки шваброй (CleanupArea + mop_mode).
## Может быть "подсчётной" — тогда регистрируется в LevelManager и считается
## к очистке на сложности HARD.

signal cleaned

const REST_SPEED := 6.0
const REST_SPIN := 0.3

@export var counts_toward_cleanup: bool = true

var _cleanup_area: Area2D


func _ready() -> void:
	add_to_group("casings")
	_cleanup_area = $CleanupArea
	_cleanup_area.body_entered.connect(_on_player_entered)
	if counts_toward_cleanup:
		var mgrs := get_tree().get_nodes_in_group("level_manager")
		if mgrs.size() > 0:
			mgrs[0].register_casing(self)


func _physics_process(_delta: float) -> void:
	if freeze:
		return
	if linear_velocity.length() < REST_SPEED and absf(angular_velocity) < REST_SPIN:
		freeze = true


## Запустить гильзу: `velocity` — начальная скорость, `spin` — угловая (рад/с).
func launch(velocity: Vector2, spin: float) -> void:
	linear_velocity = velocity
	angular_velocity = spin


func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.mop_mode:
		emit_signal("cleaned")
		queue_free()
