extends Node2D
## Recall zone: player must stand inside for 10 seconds to complete the level.
## If player leaves, countdown resets AND the zone goes on 45s cooldown.

signal recall_completed
signal recall_interrupted(cooldown: float)
signal recall_cooldown_expired

var _countdown: float = 0.0
var _countdown_max: float = 10.0
var _cooldown: float = 0.0
var _cooldown_max: float = 45.0
var _radius: float = 120.0
var _active: bool = false
var _player_inside: bool = false
var _counting: bool = false
var _area: Area2D = null


func _ready() -> void:
	_countdown_max = float(ConfigService.get_value("recall.countdown", 10.0))
	_cooldown_max = float(ConfigService.get_value("recall.cooldown", 45.0))
	_radius = float(ConfigService.get_value("recall.zone_radius", 120.0))

	_area = Area2D.new()
	_area.name = "ZoneArea"
	_area.collision_layer = 0
	_area.collision_mask = 1  # player layer
	add_child(_area)

	var col_shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = _radius
	col_shape.shape = circle
	_area.add_child(col_shape)

	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

	add_to_group("recall_zone")
	activate()


func activate() -> void:
	_active = true
	_countdown = _countdown_max
	_counting = false
	queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return
	if _cooldown > 0.0:
		_cooldown -= delta
		if _cooldown <= 0.0:
			_cooldown = 0.0
			emit_signal("recall_cooldown_expired")
		queue_redraw()
		return
	if _player_inside and not _counting:
		_counting = true
	if _counting:
		_countdown -= delta
		queue_redraw()
		if _countdown <= 0.0:
			emit_signal("recall_completed")
			queue_free()
			return
	else:
		# Waiting state – redraw every frame for pulse animation
		queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		queue_redraw()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and _counting:
		_player_inside = false
		_counting = false
		_countdown = _countdown_max
		_cooldown = _cooldown_max
		emit_signal("recall_interrupted", _cooldown_max)
		queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var font: Font = ThemeDB.fallback_font
	if _cooldown > 0.0:
		# Cooldown state: dim red ring
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, Color(0.5, 0.1, 0.1, 0.5), 3.0)
		# Cooldown progress arc (remaining cooldown fraction, clockwise from top)
		var cooldown_ratio: float = _cooldown / _cooldown_max
		var arc_end: float = -PI * 0.5 + TAU * cooldown_ratio
		draw_arc(Vector2.ZERO, _radius - 4.0, -PI * 0.5, arc_end, 64, Color(0.9, 0.2, 0.2, 0.8), 4.0)
		if font != null:
			draw_string(font, Vector2(-20.0, 8.0), "%.0f" % ceil(_cooldown), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1.0, 0.3, 0.3, 0.9))
			draw_string(font, Vector2(-10.0, -20.0), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.8, 0.2, 0.2, 0.7))
	elif _counting:
		# Active countdown: bright green ring
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, Color(0.2, 0.9, 0.3, 0.6), 3.0)
		# Countdown arc shrinking clockwise from top
		var count_ratio: float = _countdown / _countdown_max
		var arc_end: float = -PI * 0.5 + TAU * count_ratio
		draw_arc(Vector2.ZERO, _radius - 4.0, -PI * 0.5, arc_end, 64, Color(0.3, 1.0, 0.4, 0.9), 5.0)
		if font != null:
			draw_string(font, Vector2(-20.0, 8.0), "%d" % ceili(_countdown), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(1.0, 1.0, 1.0, 1.0))
			draw_string(font, Vector2(-10.0, -22.0), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.3, 1.0, 0.4, 0.9))
	else:
		# Default waiting state: yellow pulsing ring
		var pulse: float = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.003)
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, Color(0.9, 0.85, 0.1, pulse * 0.7), 3.0)
		draw_circle(Vector2.ZERO, _radius, Color(0.9, 0.85, 0.1, 0.05 * pulse))
		if font != null:
			draw_string(font, Vector2(-10.0, 8.0), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.9, 0.9, 0.2, pulse))
