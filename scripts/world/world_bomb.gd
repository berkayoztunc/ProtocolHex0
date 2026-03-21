extends Node2D

signal exploded(pos: Vector2, damage: int)

@export var countdown: float = 5.0
@export var damage: int = 200
@export var explosion_radius: float = 120.0

var _elapsed: float = 0.0
var _done: bool = false

@onready var _label: Label = $Label


func _ready() -> void:
	add_to_group("world_bombs")


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	var remaining := maxf(0.0, countdown - _elapsed)
	if _label:
		_label.text = "%.1f" % remaining
	if _elapsed >= countdown:
		_explode()


func _explode() -> void:
	_done = true
	exploded.emit(global_position, damage)
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 2  # enemy layer
	var results := space.intersect_shape(query, 32)
	for result in results:
		var body = result.get("collider")
		if body and body.has_method("take_damage"):
			body.take_damage(damage)
	queue_free()
