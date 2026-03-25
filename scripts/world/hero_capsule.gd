extends Node2D
## Hero landing capsule — plays the "arrival" animation when a run starts.
## Call start_falling(land_pos) to begin the animation.
## Emits capsule_landed when the capsule hits the ground.

signal capsule_landed

var _falling: bool = false
var _fall_target: Vector2 = Vector2.ZERO
var _fall_elapsed: float = 0.0
var _fall_duration: float = 0.75
var _done: bool = false
var _capsule_tex: Texture2D = null
var _flame_timer: float = 0.0


func _ready() -> void:
	z_index = 5
	var tex_path := "res://assets/characters/hero_capsule.png"
	if ResourceLoader.exists(tex_path):
		_capsule_tex = load(tex_path) as Texture2D


func start_falling(land_pos: Vector2) -> void:
	_fall_target = land_pos
	_falling = true
	queue_redraw()


func _process(delta: float) -> void:
	if not _falling or _done:
		return
	_fall_elapsed += delta
	var t: float = minf(_fall_elapsed / _fall_duration, 1.0)
	var start_pos: Vector2 = _fall_target + Vector2(0.0, -800.0)
	# Cubic ease-in: strong acceleration for space-capsule slam feel
	var et: float = t * t * t
	global_position = start_pos.lerp(_fall_target, et)
	queue_redraw()
	# Flame trail — emit orange/red particles above capsule while falling
	_flame_timer -= delta
	if _flame_timer <= 0.0:
		_flame_timer = 0.05
		_emit_flame_particle()
	if t >= 1.0:
		_falling = false
		_on_landed()


func _on_landed() -> void:
	_done = true
	_spawn_impact_dust()
	_spawn_landing_smoke()
	capsule_landed.emit()
	# Fade out and free the capsule node
	var tw: Tween = create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)


func _draw() -> void:
	if _done:
		return
	if _capsule_tex != null:
		# Draw the PixelLab sprite centered and scaled
		var tex_size: Vector2 = _capsule_tex.get_size()
		var target_h: float = 192.0
		var s: float = target_h / maxf(tex_size.y, 1.0)
		var rect := Rect2(-tex_size.x * s * 0.5, -tex_size.y * s * 0.5, tex_size.x * s, tex_size.y * s)
		draw_texture_rect(_capsule_tex, rect, false)
	else:
		# Fallback: programmatic draw
		draw_rect(Rect2(-10.0, -20.0, 20.0, 30.0), Color(0.55, 0.60, 0.65, 1.0))
		var dome_pts: PackedVector2Array = PackedVector2Array([
			Vector2(-10.0, -20.0),
			Vector2(0.0, -36.0),
			Vector2(10.0, -20.0)
		])
		draw_colored_polygon(dome_pts, Color(0.65, 0.70, 0.76, 1.0))
		draw_circle(Vector2(0.0, -14.0), 5.0, Color(0.45, 0.85, 1.0, 0.55))
	# Heat glow on bottom while falling — bright and pulsing
	if _falling:
		var pt: float = Time.get_ticks_msec() * 0.001
		var heat_pulse: float = 0.45 + 0.55 * abs(sin(pt * 18.0))
		draw_circle(Vector2(0.0, 12.0), 22.0, Color(1.0, 0.35, 0.05, 0.18 * heat_pulse))
		draw_circle(Vector2(0.0, 10.0), 14.0, Color(1.0, 0.55, 0.1, 0.38 * heat_pulse))
		draw_circle(Vector2(0.0, 8.0),  7.0,  Color(1.0, 0.85, 0.3, 0.70))


func _emit_flame_particle() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	for _i in 2:
		var dot := ColorRect.new()
		dot.z_index = 6
		var warm: float = randf_range(0.0, 1.0)
		dot.color = Color(1.0, 0.35 + warm * 0.45, 0.0, randf_range(0.55, 0.85))
		var r: float = randf_range(2.5, 5.5)
		dot.size = Vector2(r * 2.0, r * 2.0)
		var spread: Vector2 = Vector2(randf_range(-8.0, 8.0), randf_range(0.0, 10.0))
		dot.position = global_position + spread + Vector2(-r, -r)
		scene_root.add_child(dot)
		var dur: float = randf_range(0.12, 0.28)
		var drift: Vector2 = Vector2(randf_range(-18.0, 18.0), randf_range(-35.0, -10.0))
		var tw: Tween = dot.create_tween().set_parallel(true)
		tw.tween_property(dot, "position", dot.position + drift, dur)
		tw.tween_property(dot, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(dot.queue_free)


func _spawn_impact_dust() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	for i in 16:
		var dot: ColorRect = ColorRect.new()
		dot.z_index = 7
		dot.color = Color(0.65, 0.55, 0.40, 0.80)
		var r: float = randf_range(3.0, 7.0)
		dot.size = Vector2(r * 2.0, r * 2.0)
		var angle: float = randf_range(0.0, TAU)
		var spd: float = randf_range(45.0, 120.0)
		var vel: Vector2 = Vector2(cos(angle), sin(angle)) * spd
		dot.position = _fall_target + Vector2(-r, -r)
		scene_root.add_child(dot)
		var dur: float = randf_range(0.3, 0.7)
		var tw: Tween = dot.create_tween().set_parallel(true)
		tw.tween_property(dot, "position", dot.position + vel * dur, dur) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(dot, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(dot.queue_free)


func _spawn_landing_smoke() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	# 8 large billowing smoke puffs around the landing site
	for i in 8:
		var smoke := ColorRect.new()
		smoke.z_index = 6
		var angle: float = (TAU / 8.0) * float(i) + randf_range(-0.4, 0.4)
		var dist: float = randf_range(8.0, 42.0)
		var r: float = randf_range(24.0, 44.0)
		var grey: float = randf_range(0.60, 0.82)
		smoke.color = Color(grey, grey, grey, randf_range(0.55, 0.72))
		smoke.size = Vector2(r * 2.0, r * 2.0)
		smoke.position = _fall_target + Vector2(cos(angle) * dist - r, sin(angle) * dist - r)
		scene_root.add_child(smoke)
		# Slowly drift upward and outward while lingering
		var linger: float = randf_range(2.2, 3.2)
		var drift: Vector2 = Vector2(cos(angle), sin(angle)) * randf_range(12.0, 28.0)
		var tw: Tween = smoke.create_tween().set_parallel(true)
		tw.tween_property(smoke, "position", smoke.position + drift + Vector2(0.0, -20.0), linger + 0.4)
		# Linger then fade out in 0.4 s
		tw.tween_property(smoke, "modulate:a", 0.0, 0.4).set_delay(linger)
		tw.chain().tween_callback(smoke.queue_free)
