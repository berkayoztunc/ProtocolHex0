extends Area2D
## LootBox — dropped by enemies.
## Player must stay in contact for 3 seconds to open it.
## Emits opened(pos) which game_manager listens to.

signal opened(pos: Vector2)

const CONTACT_TO_OPEN: float = 3.0
const PULSE_SPEED: float = 2.8

var _collected: bool = false
var _player_in_contact: bool = false
var _contact_elapsed: float = 0.0
var _pulse_time: float = 0.0

var _label: Label = null


func _ready() -> void:
	add_to_group("loot_boxes")
	collision_layer = 8
	collision_mask  = 1

	# Contact label above the box
	_label = Label.new()
	_label.name = "ContactLabel"
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.9, 1.0))
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-40.0, -48.0)
	_label.size = Vector2(80.0, 20.0)
	_label.text = "LOOT"
	add_child(_label)

	# CollisionShape
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_contact = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_contact = false
		_contact_elapsed = 0.0


func _process(delta: float) -> void:
	if _collected:
		return
	_pulse_time += delta
	queue_redraw()

	if _player_in_contact:
		_contact_elapsed += delta
		var remaining: float = CONTACT_TO_OPEN - _contact_elapsed
		if remaining <= 0.0:
			_open()
		else:
			_label.text = "%.1fs" % remaining
	else:
		_label.text = "LOOT"


func _open() -> void:
	if _collected:
		return
	_collected = true
	opened.emit(global_position)
	queue_free()


func _draw() -> void:
	if _collected:
		return
	var pulse: float = 0.5 + 0.5 * sin(_pulse_time * PULSE_SPEED)

	# Outer glow rings
	draw_circle(Vector2.ZERO, 22.0 + pulse * 4.0, Color(0.1, 0.9, 0.85, 0.06 + pulse * 0.06))
	draw_circle(Vector2.ZERO, 17.0, Color(0.1, 0.9, 0.85, 0.13 + pulse * 0.07))

	# Diamond / lozenge body (6-point hexagonal polygon)
	var pts := PackedVector2Array([
		Vector2(0.0,  -14.0),  # top
		Vector2(10.0,  -7.0),  # top-right
		Vector2(10.0,   7.0),  # bot-right
		Vector2(0.0,   14.0),  # bottom
		Vector2(-10.0,  7.0),  # bot-left
		Vector2(-10.0, -7.0),  # top-left
	])
	draw_colored_polygon(pts, Color(0.06, 0.18, 0.24))
	for i in pts.size():
		draw_line(pts[i], pts[(i + 1) % pts.size()], Color(0.15, 0.88, 0.82), 1.5)

	# Energy core: bright center dot with soft halo
	draw_circle(Vector2.ZERO, 5.5 + pulse * 1.5, Color(0.1, 0.9, 0.85, 0.35 + pulse * 0.20))
	draw_circle(Vector2.ZERO, 3.0, Color(0.85, 1.0, 1.0, 0.95))

	# 3 orbiting dots rotating over time
	var orbit_r: float = 13.0
	for i in 3:
		var angle: float = _pulse_time * 2.2 + (TAU / 3.0) * float(i)
		var dp: Vector2 = Vector2(cos(angle), sin(angle)) * orbit_r
		draw_circle(dp, 2.2, Color(0.2, 1.0, 0.9, 0.80 + pulse * 0.20))

	# Progress arc when player is in contact
	if _player_in_contact and _contact_elapsed > 0.0:
		var pct: float = clampf(_contact_elapsed / CONTACT_TO_OPEN, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 22.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 24, Color(0.25, 1.0, 0.9, 0.85), 2.5)
