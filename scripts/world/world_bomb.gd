extends Node2D

signal exploded(pos: Vector2, damage: int)

@export var countdown: float = 5.0
@export var damage: int = 200
@export var explosion_radius: float = 180.0

var _elapsed: float = 0.0
var _done: bool = false
var _armed: bool = false
var _idle_tween: Tween = null
# Falling state — bomb drops from sky before planting in ground
var _falling: bool = false
var _fall_target: Vector2 = Vector2.ZERO
var _fall_speed: float = 480.0  # px/s → ~1.25 s to cover 600 px drop height
var _trail_timer: float = 0.0
var _falling_visual: ColorRect = null

@onready var _label: Label = $Label
@onready var _sprite: ColorRect = $Sprite
@onready var _area: Area2D = $Area2D


func _ready() -> void:
	add_to_group("world_bombs")
	_area.body_entered.connect(_on_body_entered)
	_label.text = "!"
	# Idle orange ↔ red pulse to draw attention
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_sprite, "color", Color(1.0, 0.60, 0.10, 1.0), 0.40)
	_idle_tween.tween_property(_sprite, "color", Color(0.85, 0.20, 0.10, 1.0), 0.40)


func _process(delta: float) -> void:
	if _falling:
		_process_falling(delta)
		return
	if _done or not _armed:
		return
	_elapsed += delta
	var remaining: float = maxf(0.0, countdown - _elapsed)
	_label.text = "%.1f" % remaining
	if _elapsed >= countdown:
		_explode()


func _on_body_entered(body: Node2D) -> void:
	if _armed or _done:
		return
	if body.is_in_group("player"):
		_arm()


# Called from game_manager after add_child — starts the aerial fall animation.
func start_falling(target_pos: Vector2) -> void:
	_fall_target = target_pos
	_falling = true
	_area.monitoring = false
	_area.monitorable = false
	if _idle_tween:
		_idle_tween.kill()
		_idle_tween = null
	_label.visible = false
	_sprite.visible = false
	# Narrow rocket silhouette pointing downward
	_falling_visual = ColorRect.new()
	_falling_visual.color = Color(0.88, 0.32, 0.04, 0.95)
	_falling_visual.size = Vector2(6.0, 20.0)
	_falling_visual.position = Vector2(-3.0, -10.0)
	add_child(_falling_visual)


func _process_falling(delta: float) -> void:
	var dir: Vector2 = _fall_target - global_position
	var step: float = _fall_speed * delta
	if dir.length() <= step:
		global_position = _fall_target
		_falling = false
		_on_landed()
	else:
		global_position += dir.normalized() * step
	# Smoke trail puffs
	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = 0.065
		_spawn_fall_smoke()


func _on_landed() -> void:
	if _falling_visual:
		_falling_visual.queue_free()
		_falling_visual = null
	# Re-enable player collision
	_area.monitoring = true
	_area.monitorable = true
	_label.text = "!"
	_label.visible = true
	_sprite.visible = true
	# Dark brownish planted-token look
	_sprite.color = Color(0.22, 0.18, 0.14, 1.0)
	# Try to swap in the Pixellab-generated asset if available
	_try_load_planted_sprite()
	# Idle pulse while waiting for player contact
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_sprite, "color", Color(0.30, 0.25, 0.18, 1.0), 0.50)
	_idle_tween.tween_property(_sprite, "color", Color(0.18, 0.14, 0.10, 1.0), 0.50)


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
	# Scale to match hero height (96 px) while preserving aspect ratio
	var hero_target_px: float = 196.0
	var tex_h: float = maxf(float(tex.get_height()), 1.0)
	var bomb_scale: float = hero_target_px / tex_h
	spr.scale = Vector2(bomb_scale, bomb_scale)
	add_child(spr)
	_sprite.visible = false
	# Switch idle pulse to the real sprite
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(spr, "modulate", Color(1.3, 0.85, 0.45, 1.0), 0.50)
	_idle_tween.tween_property(spr, "modulate", Color(0.85, 0.60, 0.30, 1.0), 0.50)


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


func _arm() -> void:
	_armed = true
	_elapsed = 0.0
	if _idle_tween:
		_idle_tween.kill()
		_idle_tween = null
	# Rapid red-yellow flash while counting down
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_sprite, "color", Color(1.0, 0.95, 0.10, 1.0), 0.18)
	_idle_tween.tween_property(_sprite, "color", Color(1.0, 0.05, 0.05, 1.0), 0.18)


func _explode() -> void:
	_done = true
	if _idle_tween:
		_idle_tween.kill()
		_idle_tween = null
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
			expl.scale = Vector2(1.8, 1.8)  # bigger explosion for 180 px radius
			scene_root.add_child(expl)
	# --- Instant shockwave rings (immediate visual feedback) ---
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
			0: ring.default_color = Color(1.0, 0.92, 0.50, 0.95)   # bright flash
			1: ring.default_color = Color(1.0, 0.40, 0.05, 0.85)   # orange fireball
			2: ring.default_color = Color(0.22, 0.18, 0.15, 0.68)  # dark smoke
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
