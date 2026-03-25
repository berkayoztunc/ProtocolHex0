extends "res://scripts/world/world_bomb.gd"
## Mayhem Bomb: dropped by Orbital Mayhem skill. Arms instantly on landing.

var _mayhem_fall_elapsed: float = 0.0
var _mayhem_fall_start: Vector2 = Vector2.ZERO
const MAYHEM_FALL_DUR: float = 0.65

func _ready() -> void:
	armed_countdown = 0.01  # Explodes almost instantly after landing
	super._ready()
	z_index = 4  # Render above background and ground tiles


func start_falling(target_pos: Vector2) -> void:
	_mayhem_fall_start = global_position
	_mayhem_fall_elapsed = 0.0
	super.start_falling(target_pos)


func _process(delta: float) -> void:
	queue_redraw()
	if _falling:
		# Cubic ease-in: starts slow then slams into the ground like a meteor
		_mayhem_fall_elapsed += delta
		var t: float = minf(_mayhem_fall_elapsed / MAYHEM_FALL_DUR, 1.0)
		var et: float = t * t * t
		global_position = _mayhem_fall_start.lerp(_fall_target, et)
		if t >= 1.0:
			_falling = false
			_on_landed()
		return
	super._process(delta)


func _draw() -> void:
	if _done:
		return
	var t: float = Time.get_ticks_msec() * 0.001
	if _falling:
		# ── Traveling light-orb (star / lens-flare style) ──
		var pulse: float = 0.80 + 0.20 * sin(t * 14.0)
		# Outer soft glow layers
		draw_circle(Vector2.ZERO, 34.0, Color(1.0, 0.55, 0.10, 0.08 * pulse))
		draw_circle(Vector2.ZERO, 26.0, Color(1.0, 0.55, 0.10, 0.16 * pulse))
		draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.72, 0.20, 0.30 * pulse))
		draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.85, 0.35, 0.65))
		# Bright white core
		draw_circle(Vector2.ZERO, 5.0,  Color(1.0, 1.0, 1.0, 1.0))
		# 4 long rotating star rays
		var spin: float = t * 2.5
		for i in 4:
			var a: float = spin + (PI * 0.5) * float(i)
			var ray_len: float = (28.0 + 4.0 * sin(t * 10.0 + float(i))) * pulse
			draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * ray_len,
					Color(1.0, 0.78, 0.20, 0.72), 2.5)
		# 4 shorter diagonal rays (opposite spin)
		for i in 4:
			var a: float = -spin * 0.7 + PI * 0.25 + (PI * 0.5) * float(i)
			draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 15.0 * pulse,
					Color(1.0, 0.62, 0.10, 0.45), 1.5)
	else:
		# ── On ground: urgent pulsing energy dome ──
		var pulse: float = 0.5 + 0.5 * abs(sin(t * 10.0))
		draw_circle(Vector2.ZERO, 30.0, Color(1.0, 0.45, 0.05, 0.10 * pulse))
		draw_circle(Vector2.ZERO, 22.0, Color(1.0, 0.45, 0.05, 0.22 * pulse))
		draw_circle(Vector2.ZERO, 13.0, Color(1.0, 0.68, 0.10, 0.55))
		draw_circle(Vector2.ZERO, 6.0,  Color(1.0, 0.90, 0.55, 0.95))


func _on_landed() -> void:
	super._on_landed()
	_sprite.visible = false   # no planted-bomb look for mayhem
	_label.visible = false    # label not needed — visual pulsing shows urgency
	# Spawn purple impact ring VFX
	var scene_root: Node = get_tree().current_scene
	if scene_root != null:
		for i in 2:
			var ring := Line2D.new()
			ring.z_index = 10
			ring.position = global_position
			for p in 28:
				var ang: float = (TAU / 28.0) * float(p)
				ring.add_point(Vector2(cos(ang), sin(ang)) * 4.0)
			ring.closed = true
			ring.width = 3.0 - float(i)
			ring.default_color = Color(1.0, 0.45, 0.05, 0.9 - float(i) * 0.25)
			scene_root.add_child(ring)
			var expand: float = 40.0 + float(i) * 25.0
			var rt: Tween = ring.create_tween().set_parallel(true)
			rt.tween_property(ring, "scale", Vector2(expand / 4.0, expand / 4.0), 0.4) \
				.set_delay(float(i) * 0.06).set_ease(Tween.EASE_OUT)
			rt.tween_property(ring, "modulate:a", 0.0, 0.4).set_delay(float(i) * 0.06 + 0.1)
			rt.chain().tween_callback(ring.queue_free)
	# No player contact required — arm immediately
	_arm()
