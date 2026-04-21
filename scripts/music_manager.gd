extends Node

## Dynamic music system.
## All 5 stems play simultaneously and stay in sync at all times.
## Changing state fades individual tracks in/out without restarting.

enum State {
	MENU,
	PRE_FIGHT,
	FIGHT,
	DIALOGUE,
	CLEANUP,
	RESULT,   # Win / lose — freezes the current mix
	SILENT,   # Fades all stems out (used during scene transitions)
}

const FADE_TIME   := 0.25   # seconds per fade
const VOLUME_ON   :=  0.0   # dB — audible
const VOLUME_OFF  := -80.0  # dB — silent, but the track keeps running for sync

# Which stems are active in each state
const STATE_TRACKS: Dictionary = {
	State.MENU:      { drums=false, bass_groove=false, bass_low=true,  guitar_chords=false, guitar_notes=true  },
	State.PRE_FIGHT: { drums=false, bass_groove=true,  bass_low=false, guitar_chords=false, guitar_notes=false },
	State.FIGHT:     { drums=true,  bass_groove=true,  bass_low=false, guitar_chords=false, guitar_notes=false },
	State.DIALOGUE:  { drums=false, bass_groove=true,  bass_low=false, guitar_chords=false, guitar_notes=true  },
	State.CLEANUP:   { drums=true,  bass_groove=false,  bass_low=true,  guitar_chords=true,  guitar_notes=true  },
	State.SILENT:    { drums=false, bass_groove=false, bass_low=false, guitar_chords=false, guitar_notes=false },
}

@export var stream_drums:         AudioStream
@export var stream_bass_groove:   AudioStream
@export var stream_bass_low:      AudioStream
@export var stream_guitar_chords: AudioStream
@export var stream_guitar_notes:  AudioStream

var _players: Dictionary = {}   # key -> AudioStreamPlayer
var _current_state: State = State.MENU
var _tween: Tween = null


func _ready() -> void:
	_build_players()
	_start_all()
	# Apply menu mix immediately without animation
	_apply_instantly(State.MENU)


func _build_players() -> void:
	var streams := {
		"drums":         stream_drums,
		"bass_groove":   stream_bass_groove,
		"bass_low":      stream_bass_low,
		"guitar_chords": stream_guitar_chords,
		"guitar_notes":  stream_guitar_notes,
	}
	for key: String in streams:
		var player := AudioStreamPlayer.new()
		player.name = key
		player.stream = streams[key]
		player.volume_db = VOLUME_OFF
		player.autoplay = false
		add_child(player)
		_players[key] = player


func _start_all() -> void:
	# Start all stems at once — they are in sync from this point on
	for key: String in _players:
		var p: AudioStreamPlayer = _players[key]
		if p.stream != null:
			p.play(0.0)


func set_state(new_state: State) -> void:
	if new_state == State.RESULT:
		# Freeze current mix — do not change anything
		_current_state = new_state
		return
	if new_state == _current_state:
		return
	_current_state = new_state
	_fade_to(new_state)


func _fade_to(state: State) -> void:
	if not STATE_TRACKS.has(state):
		return
	var track_map: Dictionary = STATE_TRACKS[state]

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)

	for key: String in _players:
		var target_db: float = VOLUME_ON if track_map.get(key, false) else VOLUME_OFF
		_tween.tween_property(_players[key], "volume_db", target_db, FADE_TIME)


func _apply_instantly(state: State) -> void:
	if not STATE_TRACKS.has(state):
		return
	var track_map: Dictionary = STATE_TRACKS[state]
	for key: String in _players:
		_players[key].volume_db = VOLUME_ON if track_map.get(key, false) else VOLUME_OFF
