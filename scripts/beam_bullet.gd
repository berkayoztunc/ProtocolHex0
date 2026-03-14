extends "res://scripts/bullet.gd"

@export var beam_length: float = 240.0
@export var beam_width: float = 14.0
@export var beam_tick_interval: float = 0.08

var _tick_timer: float = 0.0

@onready var beam_rect: ColorRect = $ColorRect
@onready var beam_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	speed = 0.0
	lifetime = maxf(lifetime, 0.12)
	super._ready()
	_configure_beam()
	call_deferred("_damage_current_overlaps")
	beam_rect.visible = false


func _draw() -> void:
	var col: Color = modulate
	col.a = 1.0
	var half_w: float = beam_width * 0.5
	# Outer glow
	var glow_rect: Rect2 = Rect2(Vector2(0, -(half_w + 4)), Vector2(beam_length, (half_w + 4) * 2.0))
	draw_rect(glow_rect, Color(col.r, col.g, col.b, 0.12), true)
	var mid_rect: Rect2 = Rect2(Vector2(0, -(half_w + 2)), Vector2(beam_length, (half_w + 2) * 2.0))
	draw_rect(mid_rect, Color(col.r, col.g, col.b, 0.3), true)
	# Core beam
	var core_rect: Rect2 = Rect2(Vector2(0, -half_w), Vector2(beam_length, beam_width))
	draw_rect(core_rect, Color(col.r * 0.7, col.g * 0.7, col.b * 0.7, 0.85), true)
	# Bright center line
	draw_line(Vector2(0, 0), Vector2(beam_length, 0), Color(1.0, 1.0, 1.0, 0.7), 2.0)


func set_direction(dir: Vector2) -> void:
	super.set_direction(dir)
	if is_node_ready():
		_configure_beam()


func _physics_process(delta: float) -> void:
	_tick_timer -= delta
	if _tick_timer > 0.0:
		return
	_tick_timer = beam_tick_interval
	_damage_current_overlaps()


func _on_body_entered(body: Node2D) -> void:
	_damage_body(body)


func _configure_beam() -> void:
	rotation = direction.angle()
	if beam_shape.shape is RectangleShape2D:
		(beam_shape.shape as RectangleShape2D).size = Vector2(beam_length, beam_width)
	beam_shape.position = Vector2(beam_length * 0.5, 0.0)
	beam_rect.offset_left = 0.0
	beam_rect.offset_top = -beam_width * 0.5
	beam_rect.offset_right = beam_length
	beam_rect.offset_bottom = beam_width * 0.5


func _damage_current_overlaps() -> void:
	for body in get_overlapping_bodies():
		if body is Node2D:
			_damage_body(body as Node2D)


func _damage_body(body: Node2D) -> void:
	if not body.is_in_group("enemies") or not body.has_method("take_damage"):
		return
	if body in _hit_enemies:
		return
	body.take_damage(damage, damage_type, is_crit)
	_hit_enemies.append(body)