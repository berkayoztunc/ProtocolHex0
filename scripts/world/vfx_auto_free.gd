extends Node2D

## Spawn this node, set global_position, then add_child.
## It will auto queue_free after auto_free_delay seconds.
@export var auto_free_delay: float = 2.5


func _ready() -> void:
	await get_tree().create_timer(auto_free_delay).timeout
	queue_free()
