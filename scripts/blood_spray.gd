extends CPUParticles2D

## Одноразовый всплеск красных частиц при попадании в противника.
## Самоудаляется после окончания эмиссии.


func _ready() -> void:
	emitting = true
	finished.connect(queue_free)
