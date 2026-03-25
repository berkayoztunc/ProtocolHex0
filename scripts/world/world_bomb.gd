extends Node2D

signal exploded(pos: Vector2, damage: int)

@export var contact_to_arm: float = 3.0  # seconds of contact needed to arm
@export var armed_countdown: float = 4.0  # seconds after arming before explosion
@export var damage: int = 200
@export var explosion_radius: float = 360.0

var _contact_elapsed: float = 0.0
var _armed_elapsed: float = 0.0
var _armed: bool = false
var _done: bool = false
var _player_in_contact: bool = false
var _falling: bool = false
var _fall_target: Vector2 = Vector2.ZERO
var _fall_speed: float = 480.0
var _trail_timer: float = 0.0
var _smoke_timer: float = 0.0   # idle smoke after landing

@onready var _label: Label = $Label
@onready var _sprite: ColorRect = $Sprite
@onready var _area: Area2D = $Area2D
@onready var _static_collision: CollisionShape2D = $StaticBody2D/CollisionShape2D


func _ready() -> void:
	add_to_group("world_bombs")
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	_area.monitoring = false
	_area.monitorable = false
	_label.visible = false
	_sprite.visible = false
	_static_collision.disabled = true


func _process(delta: float) -> void:
	if _falling:
		_process_falling(delta)
		return
	if _done:
		return
	# Continuous idle smoke rising from planted rocket
	_smoke_timer -= delta
	if _smoke_timer <= 0.0:
		_smoke_timer = 0.12
		_spawn_idle_smoke()
	# Phase 2: armed — count down regardless of contact
	if _armed:
		_armed_elapsed += delta
		var remaining: float = maxf(0.0, armed_countdown - _armed_elapsed)
		_label.text = "%d" % int(ceil(remaining))
		if _armed_elapsed >= armed_countdown:
			_explode()
		return
	# Phase 1: waiting for sustained contact to arm
	if not _player_in_contact:
		if _contact_elapsed > 0.0:
			_contact_elapsed = 0.0
			_label.text = "!"
		return
	_contact_elapsed += delta
	var remaining_arm: float = maxf(0.0, contact_to_arm - _contact_elapsed)
	_label.text = "→ %.1f" % remaining_arm
	if _contact_elapsed >= contact_to_arm:
		_arm()


func _on_body_entered(body: Node2D) -> void:
	if _done or _falling or _armed:
		return
	if body.is_in_group("player"):
		_player_in_contact = true


func _on_body_exited(body: Node2D) -> void:
	if _armed:
		return
	if body.is_in_group("player"):
		_player_in_contact = false
		_contact_elapsed = 0.0
		_label.text = "!"


func _arm() -> void:
	_armed = true
	_armed_elapsed = 0.0
	_label.text = "%d" % int(armed_countdown)


# Called from game_manager after add_child — starts the aerial fall animation.
func start_falling(target_pos: Vector2) -> void:
	_fall_target = target_pos
	_falling = true
	_area.monitoring = false
	_area.monitorable = false
	_label.visible = false
	_sprite.visible = false
	# No falling visual — only smoke trail


func _process_falling(delta: float) -> void:
	var dir: Vector2 = _fall_target - global_position
	var step: float = _fall_speed * delta
	if dir.length() <= step:
		global_position = _fall_target
		_falling = false
		_on_landed()
	else:
		global_position += dir.normalized() * step
	# Smoke trail puffs while falling
	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = 0.065
		_spawn_fall_smoke()


func _on_landed() -> void:
	# Shift collision circle up so the player cannot slide in from under the south edge
	_static_collision.position = Vector2(0.0, -12.0)
	# Unblock player movement
	_static_collision.disabled = false
	# Re-enable area detection
	_area.monitoring = true
	_area.monitorable = true
	_label.text = "!"
	_label.visible = true
	_sprite.visible = true
	_sprite.color = Color(0.22, 0.18, 0.14, 1.0)
	_try_load_planted_sprite()
	# Impact VFX: small yellow-orange burst
	_spawn_impact_particles()


func _try_load_planted_sprite() -> void:
	var path := "res://assets/pickups/bomb_planted_solid.png"
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2.ZERO
	var hero_target_px: float = 196.0
	var tex_h: float = maxf(float(tex.get_height()), 1.0)
	var bomb_scale: float = hero_target_px / tex_h
	spr.scale = Vector2(bomb_scale, bomb_scale)
	add_child(spr)
	_sprite.visible = false


func _spawn_impact_particles() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	for i in 14:
		var dot := ColorRect.new()
		dot.z_index = 8
		# Yellow to orange palette
		dot.color = Color(1.0, randf_range(0.38, 0.82), 0.04, 0.92)
		var r: float = randf_range(2.0, 5.0)
		dot.size = Vector2(r * 2.0, r * 2.0)
		var angle: float = randf_range(0.0, TAU)
		var speed: float = randf_range(35.0, 100.0)
		var vel: Vector2 = Vector2(cos(angle), sin(angle)) * speed
		dot.position = global_position + Vector2(-r, -r)
		scene_root.add_child(dot)
		var dur: float = randf_range(0.25, 0.55)
		var tw := dot.create_tween().set_parallel(true)
		tw.tween_property(dot, "position", dot.position + vel * dur, dur) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(dot, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(dot.queue_free)


func _spawn_idle_smoke() -> void:
	if _done or _falling:
		return
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var dot := ColorRect.new()
	dot.z_index = 3
	dot.color = Color(0.35, 0.28, 0.22, 0.52)
	var r: float = randf_range(3.5, 7.0)
	dot.size = Vector2(r * 2.0, r * 2.0)
	# Rises from the top of the embedded rocket
	dot.position = global_position + Vector2(-r + randf_range(-4.0, 4.0), -12.0 - r)
	scene_root.add_child(dot)
	var dur: float = randf_range(0.55, 0.9)
	var tw := dot.create_tween().set_parallel(true)
	tw.tween_property(dot, "position:y", dot.position.y - randf_range(22.0, 50.0), dur)
	tw.tween_property(dot, "position:x", dot.position.x + randf_range(-10.0, 10.0), dur)
	tw.tween_property(dot, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(dot.queue_free)


func _spawn_fall_smoke() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var dot := ColorRect.new()
	dot.z_index = 5
	dot.color = Color(0.38, 0.28, 0.18, 0.72)
	var r: float = randf_range(3.0, 6.0)
	dot.size = Vector2(r * 2.0, r * 2.0)
	dot.position = global_position + Vector2(-r + randf_range(-4.0, 4.0), -r)
	scene_root.add_child(dot)
	var tw := dot.create_tween().set_parallel(true)
	tw.tween_property(dot, "position:y", dot.position.y - randf_range(15.0, 32.0), 0.38)
	tw.tween_property(dot, "modulate:a", 0.0, 0.38)
	tw.chain().tween_callback(dot.queue_free)


func _explode() -> void:
	_done = true
	exploded.emit(global_position, damage)
	_spawn_explosion_vfx()
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


func _spawn_explosion_vfx() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	# --- CPUParticles2D explosion (fire + ember + smoke) ---
	var expl_path := "res://scenes/vfx_rocket_explosion.tscn"
	if ResourceLoader.exists(expl_path):
		var expl_scene: PackedScene = load(expl_path)
		if expl_scene != null:
			var expl: Node2D = expl_scene.instantiate()
			expl.global_position = global_position
			expl.scale = Vector2(1.8, 1.8)
			scene_root.add_child(expl)
	# --- Instant shockwave rings ---
	for i in 3:
		var ring := Line2D.new()
		ring.z_index = 10
		ring.position = global_position
		for p in 32:
			var ang: float = (TAU / 32.0) * float(p)
			ring.add_point(Vector2(cos(ang), sin(ang)) * 4.0)
		ring.closed = true
		ring.width = maxf(1.0, 4.0 - float(i) * 0.8)
		match i:
			0: ring.default_color = Color(1.0, 0.92, 0.50, 0.95)
			1: ring.default_color = Color(1.0, 0.40, 0.05, 0.85)
			2: ring.default_color = Color(0.22, 0.18, 0.15, 0.68)
		scene_root.add_child(ring)
		var delay: float = float(i) * 0.06
		var expand: float = explosion_radius * (1.0 + float(i) * 0.35) / 4.0
		var rt := ring.create_tween().set_parallel(true)
		rt.tween_property(ring, "scale", Vector2(expand, expand), 0.30 + float(i) * 0.08) \
			.set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		rt.tween_property(ring, "modulate:a", 0.0, 0.36).set_delay(delay + 0.08)
		rt.chain().tween_callback(ring.queue_free)
	# 8 fire streak lines
	for i in 8:
		var ang: float = (TAU / 8.0) * float(i) + randf_range(-0.2, 0.2)
		var streak := Line2D.new()
		streak.z_index = 10
		streak.position = global_position
		streak.add_point(Vector2.ZERO)
		streak.add_point(Vector2(cos(ang), sin(ang)) * randf_range(explosion_radius * 0.5, explosion_radius))
		streak.width = randf_range(2.0, 3.0)
		streak.default_color = Color(randf_range(0.9, 1.0), randf_range(0.25, 0.5), 0.04, 0.9)
		scene_root.add_child(streak)
		var st := streak.create_tween()
		st.tween_property(streak, "modulate:a", 0.0, 0.30)
		st.tween_callback(streak.queue_free)
