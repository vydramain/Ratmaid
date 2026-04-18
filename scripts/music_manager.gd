extends Node

## Динамическая музыкальная система.
## Все 5 треков играют одновременно и всегда синхронизированы.
## Смена состояния = fade in/out нужных дорожек, без перезапуска.

enum State {
	MENU,
	PRE_FIGHT,
	FIGHT,
	DIALOGUE,
	CLEANUP,
	RESULT,   # Победа / поражение — замораживает текущий микс
}

const FADE_TIME   := 0.25   # секунд на fade
const VOLUME_ON   :=  0.0   # dB — слышно
const VOLUME_OFF  := -80.0  # dB — беззвучно, но трек продолжает идти

# Какие дорожки активны в каждом состоянии
const STATE_TRACKS: Dictionary = {
	State.MENU:      { drums=false, bass_groove=false, bass_low=true,  guitar_chords=false, guitar_notes=true  },
	State.PRE_FIGHT: { drums=false, bass_groove=true,  bass_low=false, guitar_chords=false, guitar_notes=false },
	State.FIGHT:     { drums=true,  bass_groove=true,  bass_low=false, guitar_chords=false, guitar_notes=false },
	State.DIALOGUE:  { drums=false, bass_groove=true,  bass_low=false, guitar_chords=false, guitar_notes=true  },
	State.CLEANUP:   { drums=true,  bass_groove=false,  bass_low=true,  guitar_chords=true,  guitar_notes=true  },
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
	# Инициализируем микс для меню без анимации
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
	# Запускаем все треки одновременно — они синхронизированы с этого момента
	for key: String in _players:
		var p: AudioStreamPlayer = _players[key]
		if p.stream != null:
			p.play(0.0)


# Вызывать из LevelManager и MainMenu
func set_state(new_state: State) -> void:
	if new_state == State.RESULT:
		# Заморозить текущий микс — ничего не меняем
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
