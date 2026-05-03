extends Node

## Test-level state machine that walks the player through the full design-doc
## prologue: tutorial cleanup in the alley → bartender call → small cleanup at
## the bar → return through alley → push event → breach → combat → cleanup →
## exit. Mirrors level_manager.gd for the combat/cleanup half so existing
## props, enemies and HUD work without modification.

enum State {
	TUTORIAL_INTRO,
	TUTORIAL_ALLEY_MOP,
	TUTORIAL_BAR_CALL,
	TUTORIAL_CAFE_MOP,
	TUTORIAL_RETURN,
	PUSH_EVENT,
	BREACH,
	COMBAT,
	DIALOGUE,
	CLEANUP,
	WIN,
	LOSE_COMBAT,
	LOSE_EXIT,
	LOSE_TIMER,
}

const CLEANUP_TIME_NORMAL := 60.0
const CLEANUP_TIME_HARD := 50.0

@export var swat_scene: PackedScene

@onready var hud: CanvasLayer = $HUD
@onready var dialogue_box: CanvasLayer = $HUD/DialogueBox
@onready var glitch: CanvasLayer = $GlitchOverlay

@onready var exit_door: Area2D = $"../ExitDoor"
@onready var swat_spawn_points: Node2D = $"../SwatSpawnPoints"
@onready var trash_bin: Node2D = $"../TrashBin"
@onready var exit_arrow: Node2D = $"../ExitArrow"

@onready var cafe_entered_trigger: Area2D = $"../Triggers/CafeEntered"
@onready var bar_reached_trigger: Area2D = $"../Triggers/BarReached"
@onready var push_trigger: Area2D = $"../Triggers/PushTrigger"
@onready var breach_trigger: Area2D = $"../Triggers/BreachTrigger"
@onready var tutorial_dirt: Node2D = $"../TutorialDirt"

var current_state: State = State.TUTORIAL_INTRO
var enemies_alive := 0
var corpses_remaining := 0
var blood_remaining := 0
var casings_remaining := 0
var cleanup_timer := 0.0
var player: CharacterBody2D = null
var _aggroed_enemies := 0
var _swat_spawned := false

var _alley_dirt_remaining := 0
var _bar_dirt_remaining := 0


func _ready() -> void:
	add_to_group("level_manager")
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		player.player_died.connect(on_player_died)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.player_ref = player
		enemy.enemy_died.connect(on_enemy_died)
		enemy.aggro_started.connect(_on_aggro_started)
		enemy.aggro_ended.connect(_on_aggro_ended)
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemies_alive += 1

	exit_door.process_mode = Node.PROCESS_MODE_DISABLED
	trash_bin.deactivate()
	trash_bin.corpse_deposited.connect(on_corpse_binned)

	_wire_tutorial_dirt()

	cafe_entered_trigger.body_entered.connect(_on_cafe_entered)
	bar_reached_trigger.body_entered.connect(_on_bar_reached)
	push_trigger.body_entered.connect(_on_push_triggered)
	breach_trigger.body_entered.connect(_on_breach_triggered)

	cafe_entered_trigger.monitoring = false
	bar_reached_trigger.monitoring = false
	push_trigger.monitoring = false
	breach_trigger.monitoring = false

	_enter_tutorial_intro()


func _wire_tutorial_dirt() -> void:
	if tutorial_dirt == null:
		return
	var alley := tutorial_dirt.get_node_or_null("Alley")
	if alley != null:
		for node in alley.get_children():
			if node.has_signal("cleaned"):
				_alley_dirt_remaining += 1
				node.cleaned.connect(_on_alley_dirt_cleaned)
	var bar := tutorial_dirt.get_node_or_null("Bar")
	if bar != null:
		for node in bar.get_children():
			if node.has_signal("cleaned"):
				_bar_dirt_remaining += 1
				node.cleaned.connect(_on_bar_dirt_cleaned)


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


# ─── State transitions ────────────────────────────────────────────────────────

func _enter_tutorial_intro() -> void:
	current_state = State.TUTORIAL_INTRO
	MusicManager.set_state(MusicManager.State.PRE_FIGHT)
	if player != null:
		player.input_locked = true
	dialogue_box.dialogue_finished.connect(_on_intro_dismissed, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue("tutorial_intro")


func _on_intro_dismissed() -> void:
	_enter_tutorial_alley_mop()


func _enter_tutorial_alley_mop() -> void:
	current_state = State.TUTORIAL_ALLEY_MOP
	if player != null:
		player.input_locked = false
	hud.set_hints([["toggle_mop", "hud.hint.toggle_mop"]])


func _on_alley_dirt_cleaned() -> void:
	_alley_dirt_remaining = max(0, _alley_dirt_remaining - 1)
	if current_state == State.TUTORIAL_ALLEY_MOP and _alley_dirt_remaining == 0:
		_enter_tutorial_bar_call()


func _enter_tutorial_bar_call() -> void:
	current_state = State.TUTORIAL_BAR_CALL
	bar_reached_trigger.monitoring = true
	exit_arrow.activate(bar_reached_trigger)
	if player != null:
		player.input_locked = true
	dialogue_box.dialogue_finished.connect(_on_bar_call_dismissed, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue("tutorial_bar_call")


func _on_bar_call_dismissed() -> void:
	if player != null:
		player.input_locked = false


func _on_cafe_entered(_body: Node2D) -> void:
	# Reserved hook — not used in current flow but kept for future expansion.
	pass


func _on_bar_reached(body: Node2D) -> void:
	if current_state != State.TUTORIAL_BAR_CALL or not body.is_in_group("player"):
		return
	bar_reached_trigger.set_deferred("monitoring", false)
	_enter_tutorial_cafe_mop()


func _enter_tutorial_cafe_mop() -> void:
	current_state = State.TUTORIAL_CAFE_MOP
	exit_arrow.visible = false


func _on_bar_dirt_cleaned() -> void:
	_bar_dirt_remaining = max(0, _bar_dirt_remaining - 1)
	if current_state == State.TUTORIAL_CAFE_MOP and _bar_dirt_remaining == 0:
		_enter_tutorial_return()


func _enter_tutorial_return() -> void:
	current_state = State.TUTORIAL_RETURN
	push_trigger.monitoring = true
	exit_arrow.activate(push_trigger)
	if player != null:
		player.input_locked = true
	dialogue_box.dialogue_finished.connect(_on_return_dismissed, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue("tutorial_return")


func _on_return_dismissed() -> void:
	if player != null:
		player.input_locked = false


func _on_push_triggered(body: Node2D) -> void:
	if current_state != State.TUTORIAL_RETURN or not body.is_in_group("player"):
		return
	push_trigger.set_deferred("monitoring", false)
	_enter_push_event()


func _enter_push_event() -> void:
	current_state = State.PUSH_EVENT
	if player != null:
		player.input_locked = true
	if glitch != null:
		glitch.flash()
	dialogue_box.dialogue_finished.connect(_on_push_dismissed, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue("push_event")


func _on_push_dismissed() -> void:
	breach_trigger.monitoring = true
	exit_arrow.activate(breach_trigger)
	if player != null:
		player.input_locked = false


func _on_breach_triggered(body: Node2D) -> void:
	if current_state != State.PUSH_EVENT or not body.is_in_group("player"):
		return
	breach_trigger.set_deferred("monitoring", false)
	_enter_breach()


func _enter_breach() -> void:
	current_state = State.BREACH
	if player != null:
		player.input_locked = true
	if glitch != null:
		glitch.start_sustained()
	exit_arrow.visible = false
	dialogue_box.dialogue_finished.connect(_on_breach_dismissed, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue("breach")


func _on_breach_dismissed() -> void:
	_enter_combat()


func _enter_combat() -> void:
	current_state = State.COMBAT
	MusicManager.set_state(MusicManager.State.PRE_FIGHT)
	if player != null:
		player.input_locked = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_INHERIT


func _enter_dialogue() -> void:
	current_state = State.DIALOGUE
	MusicManager.set_state(MusicManager.State.DIALOGUE)
	if player != null:
		player.input_locked = true
	dialogue_box.dialogue_finished.connect(_on_dialogue_dismissed, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue("after_fight")


func _on_dialogue_dismissed() -> void:
	_enter_cleanup()


func _enter_cleanup() -> void:
	current_state = State.CLEANUP
	MusicManager.set_state(MusicManager.State.CLEANUP)
	if player != null:
		player.input_locked = false
	var cleanup_time := CLEANUP_TIME_HARD if Settings.difficulty == "hard" else CLEANUP_TIME_NORMAL
	cleanup_timer = cleanup_time
	hud.show_timer(cleanup_time)
	hud.show_mode(false)
	hud.set_hints([["interact", "hud.hint.pickup"], ["toggle_mop", "hud.hint.toggle_mop"]])

	exit_door.process_mode = Node.PROCESS_MODE_INHERIT
	exit_door.body_entered.connect(_on_exit_reached)

	trash_bin.activate()
	exit_arrow.visible = true
	exit_arrow.activate(exit_door)


func _enter_win() -> void:
	current_state = State.WIN
	MusicManager.set_state(MusicManager.State.RESULT)
	if glitch != null:
		glitch.stop_sustained()
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


# ─── Combat / cleanup signal handlers ─────────────────────────────────────────

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


func _on_exit_reached(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var dirty := corpses_remaining > 0 or blood_remaining > 0
	if Settings.difficulty == "hard":
		dirty = dirty or casings_remaining > 0
	if dirty:
		_enter_lose(State.LOSE_EXIT)
	else:
		_enter_win()


func on_corpse_binned() -> void:
	corpses_remaining = max(0, corpses_remaining - 1)


func on_blood_cleaned() -> void:
	blood_remaining = max(0, blood_remaining - 1)


# ─── Hooks called by props (must match level_manager's surface) ───────────────

func register_blood_splatter(splatter: Area2D) -> void:
	splatter.cleaned.connect(on_blood_cleaned)


func register_casing(casing: Node) -> void:
	casings_remaining += 1
	casing.cleaned.connect(_on_casing_cleaned)


func _on_casing_cleaned() -> void:
	casings_remaining = max(0, casings_remaining - 1)


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
