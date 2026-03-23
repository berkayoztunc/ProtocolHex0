extends Area2D

@export var speed: float = 400.0
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var damage_type: String = "physical"
var weapon_type: String = "plasma_rifle"
var is_crit: bool = false
var target_group: String = "enemies"
var _proj_sprite: Sprite2D = null
var _smoke_timer: float = 0.0
var _rocket_expl_cache: PackedScene = null
var _trail_puff_cache: PackedScene = null
# Homing: if set, the bullet steers toward this target each frame
var homing_target: Node2D = null
var homing_strength: float = 0.0  # lerp factor per second (3-10 for missiles)
var burn_chance: float = 0.0
var burn_damage: int = 0
var burn_duration: float = 3.0

# On-hit chance effects
var electric_bullet_chance: float = 0.0
var explosive_bullet_chance: float = 0.0

# Pierce: how many enemies the bullet can pass through (0 = destroy on first hit)
var pierce_count: int = 0

# Chain: after hitting, jump to nearest enemy within range
var chain_count: int = 0
var chain_range: float = 150.0
var _hit_enemies: Array[Node2D] = []

# AOE: explode on hit dealing damage in radius
var is_aoe: bool = false
var aoe_radius: float = 80.0
var aoe_damage_ratio: float = 0.6
var vfx_explosion_scale: float = 1.0  # scale multiplier for the CPUParticles explosion VFX

# Orbit: revolves around a center point instead of traveling straight
var is_orbit: bool = false
var orbit_center: Node2D = null
var orbit_radius: float = 50.0
var orbit_speed: float = 3.0
var orbit_angle: float = 0.0

# Wave: damages all enemies on screen (phase disruptor)
var is_wave: bool = false

@onready var lifetime_timer: Timer = $LifetimeTimer


func _ready() -> void:
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.start()
	lifetime_timer.timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)
	if not is_orbit:
		rotation = direction.angle()
	$ColorRect.visible = false
	_setup_projectile_sprite()
	_setup_trail_particles()


func _draw() -> void:
	if _proj_sprite != null:
		return
	var col: Color = modulate
	col.a = 1.0
	if is_orbit:
		# Orbiting orb: soft glowing circle
		draw_circle(Vector2.ZERO, 8, Color(col.r, col.g, col.b, 0.25))
		draw_circle(Vector2.ZERO, 6, Color(col.r, col.g, col.b, 0.55))
		draw_circle(Vector2.ZERO, 4, col)
		draw_circle(Vector2.ZERO, 2, Color(1.0, 1.0, 1.0, 0.8))
	else:
		# Bullet elongated glow + core
		var half_len: float = 7.0
		var half_w: float = 2.5
		draw_circle(Vector2.ZERO, half_w + 3, Color(col.r, col.g, col.b, 0.18))
		draw_circle(Vector2.ZERO, half_w + 1.5, Color(col.r, col.g, col.b, 0.45))
		# Core rect aligned to local x-axis
		var rect: Rect2 = Rect2(Vector2(-half_len, -half_w), Vector2(half_len * 2.0, half_w * 2.0))
		draw_rect(rect, col, true)
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.55), false, 1.0)
		# Bright tip
		draw_circle(Vector2(half_len, 0), half_w * 0.8, Color(1.0, 1.0, 1.0, 0.85))


func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	if not is_orbit:
		rotation = direction.angle()


func set_damage(value: int) -> void:
	damage = value


func set_damage_type(value: String) -> void:
	damage_type = value


func _physics_process(delta: float) -> void:
	if is_orbit:
		_process_orbit(delta)
	elif is_wave:
		# Wave bullets expand outward as a ring
		position += direction * speed * delta
	else:
		# Homing steering (before position update so rocket turns then moves)
		if homing_target != null and is_instance_valid(homing_target) and homing_strength > 0.0:
			var to_target: Vector2 = (homing_target.global_position - global_position).normalized()
			direction = direction.lerp(to_target, minf(homing_strength * delta, 1.0)).normalized()
			rotation = direction.angle()
		position += direction * speed * delta
		if _is_rocket_weapon():
			_smoke_timer -= delta
			if _smoke_timer <= 0.0:
				_smoke_timer = 0.065
				_spawn_smoke_puff()


func _process_orbit(delta: float) -> void:
	orbit_angle += orbit_speed * delta
	if orbit_center and is_instance_valid(orbit_center):
		global_position = orbit_center.global_position + Vector2(
			cos(orbit_angle) * orbit_radius,
			sin(orbit_angle) * orbit_radius
		)
	else:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(target_group) or not body.has_method("take_damage"):
		return
	if body in _hit_enemies:
		return

	_apply_damage_to_target(body, damage)
	if target_group == "enemies" and burn_chance > 0.0 and burn_damage > 0 and randf() <= burn_chance and body.has_method("apply_burn"):
		body.apply_burn(burn_damage, burn_duration)
	if target_group == "enemies" and electric_bullet_chance > 0.0 and randf() <= electric_bullet_chance:
		_do_electric_chain(body)
	if target_group == "enemies" and explosive_bullet_chance > 0.0 and randf() <= explosive_bullet_chance:
		_do_explosive_burst(body)
	_hit_enemies.append(body)
	_spawn_hit_vfx()

	# AOE explosion
	if is_aoe:
		_do_aoe_explosion()

	# Chain to next enemy
	if chain_count > 0:
		chain_count -= 1
		var next_target: Node2D = _find_chain_target()
		if next_target:
			direction = (next_target.global_position - global_position).normalized()
			rotation = direction.angle()
			return

	# Pierce through
	if pierce_count > 0:
		pierce_count -= 1
		return

	# Orbit bullets don't despawn on hit — they keep spinning
	if is_orbit:
		return

	queue_free()


func _do_aoe_explosion() -> void:
	_spawn_explosion_vfx()
	var enemies: Array = get_tree().get_nodes_in_group(target_group)
	var aoe_dmg: int = maxi(1, int(round(float(damage) * aoe_damage_ratio)))
	for enemy in enemies:
		if enemy in _hit_enemies:
			continue
		if enemy.has_method("take_damage"):
			var dist: float = global_position.distance_to(enemy.global_position)
			if dist <= aoe_radius:
				_apply_damage_to_target(enemy, aoe_dmg)
				_hit_enemies.append(enemy)


func _find_chain_target() -> Node2D:
	var enemies: Array = get_tree().get_nodes_in_group(target_group)
	var nearest: Node2D = null
	var nearest_dist: float = chain_range
	for enemy in enemies:
		if enemy in _hit_enemies:
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


func _apply_damage_to_target(target: Node2D, amount: int) -> void:
	if target_group == "player":
		target.take_damage(amount)
		return
	target.take_damage(amount, damage_type, is_crit)


func _setup_projectile_sprite() -> void:
	var path: String = _get_projectile_texture_path()
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return
	_proj_sprite = Sprite2D.new()
	_proj_sprite.texture = tex
	_proj_sprite.centered = true
	# No counter-rotation: sprite follows bullet direction naturally
	var projectile_scale: float = ConfigService.get_value("visual.sprite_scale.projectile", 0.9)
	var orbit_scale: float = ConfigService.get_value("visual.sprite_scale.projectile_orbit", 0.75)
	var projectile_target_px: float = minf(float(ConfigService.get_value("visual.target_px.projectile", 16.0)), 18.0)
	var orbit_target_px: float = minf(float(ConfigService.get_value("visual.target_px.projectile_orbit", 12.0)), 14.0)
	var proj_side: float = maxf(float(tex.get_width()), float(tex.get_height()))
	if proj_side > 1.0:
		projectile_scale = projectile_target_px / proj_side
		orbit_scale = orbit_target_px / proj_side
	# Rockets use larger sprites for visibility
	if _is_rocket_weapon() and not is_orbit and proj_side > 1.0:
		projectile_scale = 32.0 / proj_side
	if is_orbit:
		_proj_sprite.scale = Vector2(orbit_scale, orbit_scale)
	else:
		_proj_sprite.scale = Vector2(projectile_scale, projectile_scale)
	add_child(_proj_sprite)
	queue_redraw()


# ─── Trail Particles (burn / explosive) ─────────────────────────────────────
func _setup_trail_particles() -> void:
	if is_orbit or is_wave:
		return
	if burn_chance > 0.0:
		_add_fire_trail()
	if explosive_bullet_chance > 0.0:
		_add_explosive_trail()


func _add_fire_trail() -> void:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.amount = 8
	p.lifetime = 0.30
	p.one_shot = false
	p.explosiveness = 0.0
	p.local_coords = true
	p.direction = Vector2(-1.0, 0.0)   # behind the bullet in local space
	p.spread = 28.0
	p.initial_velocity_min = 18.0
	p.initial_velocity_max = 50.0
	p.gravity = Vector2(0.0, 0.0)
	p.scale_amount_min = 2.5
	p.scale_amount_max = clampf(4.5 + burn_chance * 6.0, 5.0, 9.0)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(1.0, 0.95, 0.55, 1.0),
		Color(1.0, 0.40, 0.05, 0.75),
		Color(0.70, 0.08, 0.00, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.50, 1.0])
	p.color_ramp = grad
	add_child(p)


func _add_explosive_trail() -> void:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.amount = 6
	p.lifetime = 0.20
	p.one_shot = false
	p.explosiveness = 0.0
	p.local_coords = true
	p.direction = Vector2(-1.0, 0.0)   # behind the bullet in local space
	p.spread = 40.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 70.0
	p.gravity = Vector2(0.0, 0.0)
	p.scale_amount_min = 1.5
	p.scale_amount_max = clampf(3.5 + explosive_bullet_chance * 5.0, 4.0, 8.0)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 0.85, 1.0),
		Color(1.0, 0.55, 0.08, 0.85),
		Color(0.85, 0.12, 0.02, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	p.color_ramp = grad
	add_child(p)


func _get_projectile_texture_path() -> String:
	var id: String = weapon_type.to_lower().replace(" ", "_")
	var alt_map: Dictionary = {
		"scatter_cannon": "scatter_pellet",
		"roket_blaster": "rocket_blaster",
	}
	if alt_map.has(id):
		id = alt_map[id]
	return "res://assets/weapons/proj_%s.png" % id


# ─── VFX Helpers ──────────────────────────────────────────────────────────────
func _load_vfx(filename: String) -> Texture2D:
	var path: String = "res://assets/vfx/" + filename
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _make_vfx_sprite(tex: Texture2D, pos: Vector2, color: Color) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.global_position = pos
	s.modulate = color
	return s


func _vfx_start_scale() -> float:
	return clampf(float(ConfigService.get_value("visual.sprite_scale.vfx_hit", 0.32)), 0.18, 0.55)


func _is_rocket_weapon() -> bool:
	return weapon_type in ["Roket Blaster", "rocket_blaster"]


func _get_rocket_expl_scene() -> PackedScene:
	if _rocket_expl_cache == null:
		var p := "res://scenes/vfx_rocket_explosion.tscn"
		if ResourceLoader.exists(p):
			_rocket_expl_cache = load(p)
	return _rocket_expl_cache


func _get_trail_puff_scene() -> PackedScene:
	if _trail_puff_cache == null:
		var p := "res://scenes/vfx_rocket_trail_puff.tscn"
		if ResourceLoader.exists(p):
			_trail_puff_cache = load(p)
	return _trail_puff_cache


func _spawn_smoke_puff() -> void:
	var puff_scene: PackedScene = _get_trail_puff_scene()
	if puff_scene != null:
		var puff: Node2D = puff_scene.instantiate()
		puff.global_position = global_position
		get_tree().current_scene.add_child(puff)
		return
	# Fallback: sprite tween when particle scene not yet imported
	var smoke_tex: Texture2D = _load_vfx("vfx_rocket_smoke_trail.png")
	var smoke: Sprite2D
	if smoke_tex != null:
		smoke = _make_vfx_sprite(smoke_tex, global_position, Color(0.60, 0.60, 0.60, 0.58))
		smoke.scale = Vector2(0.18, 0.18)
	else:
		smoke = Sprite2D.new()
		smoke.global_position = global_position
		smoke.modulate = Color(0.55, 0.55, 0.55, 0.45)
	get_tree().current_scene.add_child(smoke)
	var drift: Vector2 = Vector2(randf_range(-10.0, 10.0), randf_range(-18.0, -8.0))
	var tw := smoke.create_tween().set_parallel(true)
	tw.tween_property(smoke, "global_position", smoke.global_position + drift, 0.38)
	tw.tween_property(smoke, "scale", Vector2(0.38, 0.38), 0.38).set_ease(Tween.EASE_OUT)
	tw.tween_property(smoke, "modulate:a", 0.0, 0.38)
	tw.chain().tween_callback(smoke.queue_free)


# ─── Explosion VFX (damage-type aware) ────────────────────────────────────────
func _spawn_explosion_vfx() -> void:
	match damage_type:
		"fire":      _vfx_explosion_fire()
		"cryo":      _vfx_explosion_cryo()
		"energy":    _vfx_explosion_energy()
		"void":      _vfx_explosion_void()
		"explosive": _vfx_explosion_rocket()
		_:           _vfx_explosion_default()


func _vfx_explosion_default() -> void:
	var tex: Texture2D = _load_vfx("vfx_void_explosion_ring.png")
	if tex == null:
		return
	var s := _make_vfx_sprite(tex, global_position, modulate)
	s.modulate.a = 0.8
	var ring_start: float = ConfigService.get_value("visual.sprite_scale.vfx_ring_start", 0.15)
	s.scale = Vector2(ring_start, ring_start)
	get_tree().current_scene.add_child(s)
	var target_scale: float = aoe_radius / maxf(tex.get_width() * 0.5, 1.0)
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(target_scale, target_scale), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(s, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(s.queue_free)


func _vfx_explosion_fire() -> void:
	var ring_tex: Texture2D = _load_vfx("vfx_void_explosion_ring.png")
	var spark_tex: Texture2D = _load_vfx("vfx_hit_spark.png")
	# Central bright flash
	if spark_tex != null:
		var flash := _make_vfx_sprite(spark_tex, global_position, Color(1.0, 0.9, 0.3, 1.0))
		flash.scale = Vector2(0.9, 0.9)
		get_tree().current_scene.add_child(flash)
		var ft := flash.create_tween().set_parallel(true)
		ft.tween_property(flash, "scale", Vector2(2.2, 2.2), 0.14).set_ease(Tween.EASE_OUT)
		ft.tween_property(flash, "modulate:a", 0.0, 0.14)
		ft.chain().tween_callback(flash.queue_free)
	# Orange-red main ring
	if ring_tex != null:
		var target_scale: float = aoe_radius / maxf(ring_tex.get_width() * 0.5, 1.0)
		var ring := _make_vfx_sprite(ring_tex, global_position, Color(1.0, 0.38, 0.05, 0.9))
		ring.scale = Vector2(0.1, 0.1)
		get_tree().current_scene.add_child(ring)
		var rt := ring.create_tween().set_parallel(true)
		rt.tween_property(ring, "scale", Vector2(target_scale, target_scale), 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		rt.tween_property(ring, "modulate:a", 0.0, 0.38)
		rt.chain().tween_callback(ring.queue_free)
	# Outer heat shimmer
	var heat_tex: Texture2D = _load_vfx("vfx_gravity_wave_ring.png")
	if heat_tex != null:
		var heat_scale: float = (aoe_radius * 1.15) / maxf(heat_tex.get_width() * 0.5, 1.0)
		var heat := _make_vfx_sprite(heat_tex, global_position, Color(1.0, 0.55, 0.15, 0.5))
		heat.scale = Vector2(0.05, 0.05)
		get_tree().current_scene.add_child(heat)
		var ht := heat.create_tween().set_parallel(true)
		ht.tween_property(heat, "scale", Vector2(heat_scale, heat_scale), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		ht.tween_property(heat, "modulate:a", 0.0, 0.4)
		ht.chain().tween_callback(heat.queue_free)


func _vfx_explosion_cryo() -> void:
	var ring_tex: Texture2D = _load_vfx("vfx_void_explosion_ring.png")
	if ring_tex != null:
		var target_scale: float = aoe_radius / maxf(ring_tex.get_width() * 0.5, 1.0)
		var ring := _make_vfx_sprite(ring_tex, global_position, Color(0.45, 0.9, 1.0, 0.85))
		ring.scale = Vector2(0.08, 0.08)
		get_tree().current_scene.add_child(ring)
		var rt := ring.create_tween().set_parallel(true)
		rt.tween_property(ring, "scale", Vector2(target_scale, target_scale), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		rt.tween_property(ring, "modulate:a", 0.0, 0.4)
		rt.chain().tween_callback(ring.queue_free)
	# 8 ice shards radiating outward
	for i in 8:
		var ang: float = (TAU / 8.0) * float(i) + randf_range(-0.15, 0.15)
		var shard := Line2D.new()
		shard.position = global_position
		shard.add_point(Vector2.ZERO)
		shard.add_point(Vector2(cos(ang), sin(ang)) * randf_range(aoe_radius * 0.5, aoe_radius * 0.85))
		shard.width = 2.0
		shard.default_color = Color(0.65, 0.95, 1.0, 0.8)
		get_tree().current_scene.add_child(shard)
		var st := shard.create_tween()
		st.tween_property(shard, "modulate:a", 0.0, 0.35)
		st.tween_callback(shard.queue_free)


func _vfx_explosion_energy() -> void:
	var ring_tex: Texture2D = _load_vfx("vfx_gravity_wave_ring.png")
	if ring_tex == null:
		ring_tex = _load_vfx("vfx_void_explosion_ring.png")
	if ring_tex != null:
		var target_scale: float = aoe_radius / maxf(ring_tex.get_width() * 0.5, 1.0)
		var ring := _make_vfx_sprite(ring_tex, global_position, Color(0.6, 0.85, 1.0, 0.9))
		ring.scale = Vector2(0.05, 0.05)
		get_tree().current_scene.add_child(ring)
		var rt := ring.create_tween().set_parallel(true)
		rt.tween_property(ring, "scale", Vector2(target_scale, target_scale), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		rt.tween_property(ring, "modulate:a", 0.0, 0.25)
		rt.chain().tween_callback(ring.queue_free)
	# 5 lightning branches from centre
	for i in 5:
		var ang: float = (TAU / 5.0) * float(i) + randf_range(-0.3, 0.3)
		var reach: float = randf_range(aoe_radius * 0.4, aoe_radius * 0.9)
		var end_pt: Vector2 = Vector2(cos(ang), sin(ang)) * reach
		var mid_pt: Vector2 = end_pt * 0.5 + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
		var bolt := Line2D.new()
		bolt.position = global_position
		bolt.add_point(Vector2.ZERO)
		bolt.add_point(mid_pt)
		bolt.add_point(end_pt)
		bolt.width = 2.2
		bolt.default_color = Color(0.75, 0.92, 1.0, 0.9)
		get_tree().current_scene.add_child(bolt)
		var bt := bolt.create_tween()
		bt.tween_property(bolt, "modulate:a", 0.0, 0.2)
		bt.tween_callback(bolt.queue_free)


func _vfx_explosion_void() -> void:
	var ring_tex: Texture2D = _load_vfx("vfx_void_explosion_ring.png")
	if ring_tex != null:
		var target_scale: float = aoe_radius / maxf(ring_tex.get_width() * 0.5, 1.0)
		# Ring 1: implodes inward
		var ring1 := _make_vfx_sprite(ring_tex, global_position, Color(0.6, 0.2, 1.0, 0.85))
		ring1.scale = Vector2(target_scale * 0.8, target_scale * 0.8)
		get_tree().current_scene.add_child(ring1)
		var rt1 := ring1.create_tween().set_parallel(true)
		rt1.tween_property(ring1, "scale", Vector2(0.05, 0.05), 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		rt1.tween_property(ring1, "modulate:a", 0.0, 0.18)
		rt1.chain().tween_callback(ring1.queue_free)
		# Ring 2: explodes outward after implosion
		var ring2 := _make_vfx_sprite(ring_tex, global_position, Color(0.45, 0.1, 0.85, 0.9))
		ring2.scale = Vector2(0.05, 0.05)
		get_tree().current_scene.add_child(ring2)
		var rt2 := ring2.create_tween().set_parallel(true)
		rt2.tween_property(ring2, "scale", Vector2(target_scale, target_scale), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).set_delay(0.12)
		rt2.tween_property(ring2, "modulate:a", 0.0, 0.28).set_delay(0.12)
		rt2.chain().tween_callback(ring2.queue_free)
	# Outer gravity wave
	var wave_tex: Texture2D = _load_vfx("vfx_gravity_wave_ring.png")
	if wave_tex != null:
		var wave_scale: float = (aoe_radius * 1.3) / maxf(wave_tex.get_width() * 0.5, 1.0)
		var wave := _make_vfx_sprite(wave_tex, global_position, Color(0.7, 0.3, 1.0, 0.6))
		wave.scale = Vector2(0.05, 0.05)
		get_tree().current_scene.add_child(wave)
		var wt := wave.create_tween().set_parallel(true)
		wt.tween_property(wave, "scale", Vector2(wave_scale, wave_scale), 0.3).set_ease(Tween.EASE_OUT).set_delay(0.1)
		wt.tween_property(wave, "modulate:a", 0.0, 0.35).set_delay(0.1)
		wt.chain().tween_callback(wave.queue_free)


func _vfx_explosion_rocket() -> void:
	# --- GPUParticles-based explosion (fire + ember + smoke) ---
	var expl_scene: PackedScene = _get_rocket_expl_scene()
	if expl_scene != null:
		var expl: Node2D = expl_scene.instantiate()
		expl.global_position = global_position
		expl.scale = Vector2(vfx_explosion_scale, vfx_explosion_scale)
		get_tree().current_scene.add_child(expl)
	# --- Instant shockwave ring for immediate visual feedback ---
	var spark_tex: Texture2D = _load_vfx("vfx_hit_spark.png")
	if spark_tex != null:
		var flash := _make_vfx_sprite(spark_tex, global_position, Color(1.0, 0.96, 0.70, 1.0))
		flash.scale = Vector2(1.6, 1.6)
		get_tree().current_scene.add_child(flash)
		var ft := flash.create_tween().set_parallel(true)
		ft.tween_property(flash, "scale", Vector2(3.2, 3.2), 0.10).set_ease(Tween.EASE_OUT)
		ft.tween_property(flash, "modulate:a", 0.0, 0.12)
		ft.chain().tween_callback(flash.queue_free)
	var ring_tex: Texture2D = _load_vfx("vfx_void_explosion_ring.png")
	if ring_tex != null:
		var target_scale: float = aoe_radius / maxf(ring_tex.get_width() * 0.5, 1.0)
		var ring := _make_vfx_sprite(ring_tex, global_position, Color(1.0, 0.52, 0.06, 0.88))
		ring.scale = Vector2(0.10, 0.10)
		get_tree().current_scene.add_child(ring)
		var rt := ring.create_tween().set_parallel(true)
		rt.tween_property(ring, "scale", Vector2(target_scale, target_scale), 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		rt.tween_property(ring, "modulate:a", 0.0, 0.24)
		rt.chain().tween_callback(ring.queue_free)


func _do_electric_chain(hit_enemy: Node2D) -> void:
	var chain_dmg: int = maxi(1, int(round(float(damage) * 0.6)))
	var chain_range: float = 200.0
	var max_chains: int = 3
	var enemies: Array = get_tree().get_nodes_in_group(target_group)
	var chained: int = 0
	for enemy in enemies:
		if chained >= max_chains:
			break
		if enemy == hit_enemy or enemy in _hit_enemies:
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= chain_range and enemy.has_method("take_damage"):
			enemy.take_damage(chain_dmg, "energy", false)
			_hit_enemies.append(enemy)
			_spawn_volt_chain_vfx(hit_enemy.global_position, enemy.global_position)
			chained += 1


func _do_explosive_burst(_hit_enemy: Node2D) -> void:
	var burst_dmg: int = maxi(1, int(round(float(damage) * 0.5)))
	var burst_radius: float = 80.0
	var enemies: Array = get_tree().get_nodes_in_group(target_group)
	for enemy in enemies:
		if enemy in _hit_enemies:
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= burst_radius and enemy.has_method("take_damage"):
			enemy.take_damage(burst_dmg, "explosive", false)
			_hit_enemies.append(enemy)
	_spawn_explosion_vfx()


func _spawn_volt_chain_vfx(from_pos: Vector2, to_pos: Vector2) -> void:
	var line: Line2D = Line2D.new()
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.width = 2.5
	line.default_color = Color(0.55, 0.75, 1.0, 0.9)
	get_tree().current_scene.add_child(line)
	var tween: Tween = line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.25)
	tween.tween_callback(line.queue_free)


# ─── Hit VFX (damage-type aware) ──────────────────────────────────────────────
func _spawn_hit_vfx() -> void:
	match damage_type:
		"fire":   _vfx_hit_fire()
		"cryo":   _vfx_hit_cryo()
		"energy": _vfx_hit_energy()
		"nano":   _vfx_hit_nano()
		"void":   _vfx_hit_void()
		_:        _vfx_hit_physical()


func _vfx_hit_physical() -> void:
	var tex: Texture2D = _load_vfx("vfx_hit_spark.png")
	if tex == null:
		return
	var sc: float = _vfx_start_scale()
	var s := _make_vfx_sprite(tex, global_position, Color(1.0, 0.95, 0.4, 0.9))
	s.scale = Vector2(sc, sc)
	get_tree().current_scene.add_child(s)
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(sc * 1.6, sc * 1.6), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(s, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(s.queue_free)


func _vfx_hit_fire() -> void:
	var tex: Texture2D = _load_vfx("vfx_hit_spark.png")
	if tex == null:
		return
	# Orange-red spark, larger burst
	var sc: float = _vfx_start_scale() * 1.3
	var s := _make_vfx_sprite(tex, global_position, Color(1.0, 0.35, 0.05, 1.0))
	s.scale = Vector2(sc, sc)
	get_tree().current_scene.add_child(s)
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(sc * 2.0, sc * 2.0), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(s, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(s.queue_free)
	# Small ember ring
	var ring_tex: Texture2D = _load_vfx("vfx_void_explosion_ring.png")
	if ring_tex == null:
		return
	var ring := _make_vfx_sprite(ring_tex, global_position, Color(1.0, 0.5, 0.1, 0.7))
	ring.scale = Vector2(0.05, 0.05)
	get_tree().current_scene.add_child(ring)
	var tw2 := ring.create_tween().set_parallel(true)
	tw2.tween_property(ring, "scale", Vector2(0.3, 0.3), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw2.tween_property(ring, "modulate:a", 0.0, 0.22)
	tw2.chain().tween_callback(ring.queue_free)


func _vfx_hit_cryo() -> void:
	var tex: Texture2D = _load_vfx("vfx_hit_spark.png")
	if tex == null:
		return
	# Icy blue spark
	var sc: float = _vfx_start_scale()
	var s := _make_vfx_sprite(tex, global_position, Color(0.5, 0.9, 1.0, 0.9))
	s.scale = Vector2(sc, sc)
	get_tree().current_scene.add_child(s)
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(sc * 1.4, sc * 1.4), 0.14).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(s.queue_free)
	# 5 ice shards radiating from hit point
	var base_ang: float = direction.angle()
	for i in 5:
		var ang: float = base_ang + (TAU / 5.0) * float(i) + randf_range(-0.2, 0.2)
		var shard := Line2D.new()
		shard.position = global_position
		shard.add_point(Vector2.ZERO)
		shard.add_point(Vector2(cos(ang), sin(ang)) * randf_range(10.0, 18.0))
		shard.width = 1.5
		shard.default_color = Color(0.6, 0.95, 1.0, 0.85)
		get_tree().current_scene.add_child(shard)
		var st := shard.create_tween()
		st.tween_property(shard, "modulate:a", 0.0, 0.22)
		st.tween_callback(shard.queue_free)


func _vfx_hit_energy() -> void:
	var tex: Texture2D = _load_vfx("vfx_hit_spark.png")
	if tex == null:
		return
	# Large bright flash that instantly contracts — electric feel
	var sc: float = _vfx_start_scale() * 1.8
	var s := _make_vfx_sprite(tex, global_position, Color(0.75, 0.9, 1.0, 1.0))
	s.scale = Vector2(sc * 1.4, sc * 1.4)
	get_tree().current_scene.add_child(s)
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(sc * 0.4, sc * 0.4), 0.07).set_ease(Tween.EASE_IN)
	tw.tween_property(s, "modulate:a", 0.0, 0.08)
	tw.chain().tween_callback(s.queue_free)
	# 2 short lightning jags at impact
	var base_ang: float = direction.angle()
	for i in 2:
		var ang: float = base_ang + randf_range(-0.6, 0.6) + PI * float(i) * 0.45
		var end_pt: Vector2 = Vector2(cos(ang), sin(ang)) * randf_range(12.0, 22.0)
		var mid_pt: Vector2 = end_pt * 0.5 + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
		var jag := Line2D.new()
		jag.position = global_position
		jag.add_point(Vector2.ZERO)
		jag.add_point(mid_pt)
		jag.add_point(end_pt)
		jag.width = 1.8
		jag.default_color = Color(0.8, 0.95, 1.0, 0.9)
		get_tree().current_scene.add_child(jag)
		var jt := jag.create_tween()
		jt.tween_property(jag, "modulate:a", 0.0, 0.09)
		jt.tween_callback(jag.queue_free)


func _vfx_hit_nano() -> void:
	var tex: Texture2D = _load_vfx("vfx_hit_spark.png")
	if tex == null:
		return
	# Soft green expanding pulse
	var sc: float = _vfx_start_scale() * 0.9
	var s := _make_vfx_sprite(tex, global_position, Color(0.3, 1.0, 0.5, 0.8))
	s.scale = Vector2(sc, sc)
	get_tree().current_scene.add_child(s)
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(sc * 2.2, sc * 2.2), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(s, "modulate:a", 0.0, 0.28)
	tw.chain().tween_callback(s.queue_free)
	# Healing cross — 2 perpendicular Line2Ds
	for i in 2:
		var cross := Line2D.new()
		cross.position = global_position
		var perp_ang: float = PI * 0.5 * float(i)
		cross.add_point(Vector2(cos(perp_ang), sin(perp_ang)) * 7.0)
		cross.add_point(Vector2(-cos(perp_ang), -sin(perp_ang)) * 7.0)
		cross.width = 2.0
		cross.default_color = Color(0.25, 1.0, 0.45, 0.9)
		get_tree().current_scene.add_child(cross)
		var ct := cross.create_tween().set_parallel(true)
		ct.tween_property(cross, "scale", Vector2(1.8, 1.8), 0.3).set_ease(Tween.EASE_OUT)
		ct.tween_property(cross, "modulate:a", 0.0, 0.3)
		ct.chain().tween_callback(cross.queue_free)


func _vfx_hit_void() -> void:
	var tex: Texture2D = _load_vfx("vfx_void_explosion_ring.png")
	if tex == null:
		return
	# Ring that implodes inward — sucked into void
	var s := _make_vfx_sprite(tex, global_position, Color(0.65, 0.3, 1.0, 0.85))
	s.scale = Vector2(0.35, 0.35)
	get_tree().current_scene.add_child(s)
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(0.05, 0.05), 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(s, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(s.queue_free)
