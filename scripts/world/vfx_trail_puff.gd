extends CPUParticles2D

## Standalone one-shot smoke puff. Spawn at bullet position, add to scene root.
## Auto-frees after all particles have finished.

func _ready() -> void:
	emitting = true
	await get_tree().create_timer(lifetime + 0.35).timeout
	queue_free()
