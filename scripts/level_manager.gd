extends Node

enum State { COMBAT, DIALOGUE, CLEANUP, WIN, LOSE_COMBAT, LOSE_EXIT, LOSE_TIMER }

const CLEANUP_TIME := 60.0

@export var trash_bin_scene: PackedScene
@export var swat_scene: PackedScene

@onready var hud: CanvasLayer = $HUD
@onready var dialogue_box: CanvasLayer = $HUD/DialogueBox
@onready var exit_door: Area2D = $"../ExitDoor"
@onready var swat_spawn_points: Node2D = $"../SwatSpawnPoints"

var current_state: State = State.COMBAT
var enemies_alive := 0
var corpses_remaining := 0
var blood_remaining := 0
var cleanup_timer := 0.0
var player: CharacterBody2D = null
var _trash_bin: Node2D = null
var _aggroed_enemies := 0
var _swat_spawned := false


func _ready() -> void:
	add_to_group("level_manager")
	# Найти игрока
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		player.player_died.connect(on_player_died)

	# Назначить ссылку на игрока врагам и посчитать их
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.player_ref = player
		enemy.enemy_died.connect(on_enemy_died)
		enemy.aggro_started.connect(_on_aggro_started)
		enemy.aggro_ended.connect(_on_aggro_ended)
		enemies_alive += 1

	# Отключить ExitDoor до фазы уборки
	exit_door.process_mode = Node.PROCESS_MODE_DISABLED

	_enter_combat()


func _process(delta: float) -> void:
	if current_state != State.CLEANUP:
		return
	if cleanup_timer > 0.0:
		cleanup_timer -= delta
		if cleanup_timer <= 0.0:
			cleanup_timer = 0.0
			if not _swat_spawned:
				_swat_spawned = true
				_spawn_swat()
	hud.update_timer(cleanup_timer)


# ─── Переходы состояний ───────────────────────────────────────────────────────

func _enter_combat() -> void:
	current_state = State.COMBAT
	MusicManager.set_state(MusicManager.State.PRE_FIGHT)


func _enter_dialogue() -> void:
	current_state = State.DIALOGUE
	MusicManager.set_state(MusicManager.State.DIALOGUE)
	dialogue_box.start_dialogue()
	dialogue_box.dialogue_finished.connect(on_dialogue_dismissed, CONNECT_ONE_SHOT)


func _enter_cleanup() -> void:
	current_state = State.CLEANUP
	MusicManager.set_state(MusicManager.State.CLEANUP)
	cleanup_timer = CLEANUP_TIME
	hud.show_timer(CLEANUP_TIME)
	hud.show_mode(false)
	hud.set_hints([["interact", "Взять труп"], ["toggle_mop", "Швабра/Пистолет"]])

	# Активировать выход
	exit_door.process_mode = Node.PROCESS_MODE_INHERIT
	exit_door.body_entered.connect(on_exit_reached)

	# Заспавнить мусорный ящик рядом с игроком
	if trash_bin_scene != null and player != null:
		_trash_bin = trash_bin_scene.instantiate()
		_trash_bin.global_position = player.global_position + Vector2(-80, 0)
		get_parent().add_child(_trash_bin)
		_trash_bin.corpse_deposited.connect(on_corpse_binned)


func _enter_win() -> void:
	current_state = State.WIN
	MusicManager.set_state(MusicManager.State.RESULT)
	hud.hide_timer()
	hud.clear_hints()
	hud.show_victory()


func _enter_lose(reason: State) -> void:
	current_state = reason
	MusicManager.set_state(MusicManager.State.RESULT)
	hud.hide_timer()
	hud.clear_hints()
	match reason:
		State.LOSE_COMBAT:
			hud.show_gameover("combat")
		State.LOSE_EXIT:
			hud.show_gameover("exit_early")
		State.LOSE_TIMER:
			hud.show_gameover("timer")


# ─── Обработчики сигналов ─────────────────────────────────────────────────────

func on_enemy_died() -> void:
	enemies_alive -= 1
	corpses_remaining += 1
	blood_remaining += 1
	if enemies_alive <= 0:
		_enter_dialogue()


func on_player_died() -> void:
	if current_state == State.COMBAT:
		_enter_lose(State.LOSE_COMBAT)
	else:
		_enter_lose(State.LOSE_TIMER)


func on_dialogue_dismissed() -> void:
	_enter_cleanup()


func on_exit_reached(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if corpses_remaining > 0 or blood_remaining > 0:
		_enter_lose(State.LOSE_EXIT)
	else:
		_enter_win()


func on_corpse_binned() -> void:
	corpses_remaining = max(0, corpses_remaining - 1)
	_check_cleanup_hint()


func on_blood_cleaned() -> void:
	blood_remaining = max(0, blood_remaining - 1)
	_check_cleanup_hint()


# ─── Вспомогательные ──────────────────────────────────────────────────────────

func register_blood_splatter(splatter: Area2D) -> void:
	splatter.cleaned.connect(on_blood_cleaned)


func _check_cleanup_hint() -> void:
	# Заглушка: в будущем можно показывать подсказку "Всё чисто! Уходи!"
	pass


func _spawn_swat() -> void:
	if swat_scene == null or swat_spawn_points == null:
		return
	for point in swat_spawn_points.get_children():
		var swat := swat_scene.instantiate()
		swat.global_position = point.global_position
		swat.player_ref = player
		get_parent().add_child(swat)


func notify_mode_changed(is_mop: bool) -> void:
	hud.show_mode(is_mop)


func _on_aggro_started() -> void:
	_aggroed_enemies += 1
	if current_state == State.COMBAT:
		MusicManager.set_state(MusicManager.State.FIGHT)


func _on_aggro_ended() -> void:
	_aggroed_enemies = max(0, _aggroed_enemies - 1)
	if _aggroed_enemies == 0 and current_state == State.COMBAT:
		MusicManager.set_state(MusicManager.State.PRE_FIGHT)
