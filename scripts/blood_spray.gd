extends CPUParticles2D

## One-shot red particle burst on enemy hit. Self-frees when emission ends.


func _ready() -> void:
	emitting = true
	finished.connect(queue_free)
