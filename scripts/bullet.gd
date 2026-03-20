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
var burn_chance: float = 0.0
var burn_damage: int = 0
var burn_duration: float = 3.0

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
		position += direction * speed * delta


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
	_proj_sprite.rotation = -rotation  # counter-rotate so sprite stays upright relative to bullet
	var projectile_scale: float = ConfigService.get_value("visual.sprite_scale.projectile", 0.9)
	var orbit_scale: float = ConfigService.get_value("visual.sprite_scale.projectile_orbit", 0.75)
	var projectile_target_px: float = minf(float(ConfigService.get_value("visual.target_px.projectile", 16.0)), 18.0)
	var orbit_target_px: float = minf(float(ConfigService.get_value("visual.target_px.projectile_orbit", 12.0)), 14.0)
	var proj_side: float = maxf(float(tex.get_width()), float(tex.get_height()))
	if proj_side > 1.0:
		projectile_scale = projectile_target_px / proj_side
		orbit_scale = orbit_target_px / proj_side
	if is_orbit:
		_proj_sprite.scale = Vector2(orbit_scale, orbit_scale)
	else:
		_proj_sprite.scale = Vector2(projectile_scale, projectile_scale)
	add_child(_proj_sprite)
	queue_redraw()


func _get_projectile_texture_path() -> String:
	var id: String = weapon_type.to_lower().replace(" ", "_")
	var alt_map: Dictionary = {
		"scatter_cannon": "scatter_pellet",
	}
	if alt_map.has(id):
		id = alt_map[id]
	return "res://assets/weapons/proj_%s.png" % id


func _spawn_explosion_vfx() -> void:
	var vfx_path: String = "res://assets/vfx/vfx_void_explosion_ring.png"
	if not ResourceLoader.exists(vfx_path):
		return
	var tex: Texture2D = load(vfx_path) as Texture2D
	if tex == null:
		return
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	sprite.global_position = global_position
	var ring_start: float = ConfigService.get_value("visual.sprite_scale.vfx_ring_start", 0.15)
	sprite.scale = Vector2(ring_start, ring_start)
	sprite.modulate = modulate
	sprite.modulate.a = 0.8
	get_tree().current_scene.add_child(sprite)
	var target_scale: float = aoe_radius / maxf(tex.get_width() * 0.5, 1.0)
	var tween: Tween = sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(target_scale, target_scale), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(sprite.queue_free)


func _spawn_hit_vfx() -> void:
	var vfx_path: String = "res://assets/vfx/vfx_hit_spark.png"
	if not ResourceLoader.exists(vfx_path):
		return
	var tex: Texture2D = load(vfx_path) as Texture2D
	if tex == null:
		return
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	sprite.global_position = global_position
	var start_scale: float = float(ConfigService.get_value("visual.sprite_scale.vfx_hit", 0.32))
	start_scale = clampf(start_scale, 0.18, 0.55)
	sprite.scale = Vector2(start_scale, start_scale)
	sprite.modulate = modulate
	sprite.modulate.a = 0.9
	get_tree().current_scene.add_child(sprite)
	var tween: Tween = sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(start_scale * 1.55, start_scale * 1.55), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(sprite.queue_free)
