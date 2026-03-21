extends CharacterBody2D

signal died(pos: Vector2)

@export var speed: float = 80.0
@export var health: int = 20
@export var damage: int = 10
@export var damage_cooldown: float = 1.0
@export var physical_resistance: float = 0.0
@export var explosive_resistance: float = 0.0

var target: Node2D = null
var can_damage: bool = true
var is_elite: bool = false
var max_health: int = 20
var _burn_damage: int = 0
var _burn_time_left: float = 0.0
var _burn_tick_accumulator: float = 0.0
var _chill_slow_pct: float = 0.0
var _chill_time_left: float = 0.0
var _generated_sprite: Sprite2D = null
var _use_generated_sprite: bool = false
var _animated_sprite: AnimatedSprite2D = null
var _enemy_direction: String = "south"
var archetype_id: String = "runner"
var archetype_data: Dictionary = {}
var _east_west_only: bool = false
var can_shoot: bool = false
var fire_cooldown: float = 1.6
var fire_range: float = 260.0
var projectile_speed: float = 280.0
var projectile_lifetime: float = 1.4
var projectile_damage_ratio: float = 0.8
var projectile_scene_type: String = "standard"
var projectile_damage_type: String = "physical"
var projectile_aoe_enabled: bool = false
var projectile_aoe_radius: float = 60.0
var projectile_aoe_damage_ratio: float = 0.65
var projectile_color: Color = Color(1.0, 0.6, 0.3, 1.0)
var projectile_name: String = "plasma_rifle"
var _fire_timer: float = 0.0
var _behavior_time: float = 0.0

var damage_number_scene: PackedScene = preload("res://scenes/damage_number.tscn")
var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
var aoe_bullet_scene: PackedScene = preload("res://scenes/aoe_bullet.tscn")

@onready var damage_timer: Timer = $DamageTimer
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel


func _ready() -> void:
	add_to_group("enemies")
	if archetype_data.is_empty():
		var default_archetype: Variant = ConfigService.get_value("enemies.archetypes.runner", null)
		if default_archetype != null and typeof(default_archetype) == TYPE_DICTIONARY:
			setup_from_archetype("runner", default_archetype as Dictionary)
	max_health = health
	damage_timer.wait_time = damage_cooldown
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	_update_health_bar()
	health_bar.visible = false
	health_label.visible = false
	_setup_animated_sprite()
	if _animated_sprite == null:
		_setup_generated_sprite()
	_fire_timer = randf_range(0.0, fire_cooldown)


func setup_from_archetype(new_archetype_id: String, data: Dictionary) -> void:
	archetype_id = new_archetype_id
	archetype_data = data.duplicate(true)
	health = int(archetype_data.get("base_health", health))
	max_health = health
	speed = float(archetype_data.get("base_speed", speed))
	damage = int(archetype_data.get("base_damage", damage))
	physical_resistance = float(archetype_data.get("physical_resistance", physical_resistance))
	explosive_resistance = float(archetype_data.get("explosive_resistance", explosive_resistance))
	can_shoot = bool(archetype_data.get("is_ranged", false))
	_setup_fire_profile(str(archetype_data.get("fire_profile_id", "")))


func _setup_fire_profile(fire_profile_id: String) -> void:
	if fire_profile_id.is_empty():
		can_shoot = false if not bool(archetype_data.get("is_ranged", false)) else can_shoot
		return
	var profile: Variant = ConfigService.get_value("enemies.fire_profiles.%s" % fire_profile_id, null)
	if profile == null or typeof(profile) != TYPE_DICTIONARY:
		return
	var data: Dictionary = profile as Dictionary
	projectile_scene_type = str(data.get("projectile_scene", projectile_scene_type))
	fire_cooldown = maxf(0.2, float(data.get("cooldown", fire_cooldown)))
	fire_range = maxf(40.0, float(data.get("range", fire_range)))
	projectile_speed = maxf(80.0, float(data.get("bullet_speed", projectile_speed)))
	projectile_lifetime = maxf(0.2, float(data.get("bullet_lifetime", projectile_lifetime)))
	projectile_damage_ratio = clampf(float(data.get("damage_ratio", projectile_damage_ratio)), 0.1, 2.2)
	projectile_damage_type = str(data.get("damage_type", projectile_damage_type))
	projectile_aoe_enabled = bool(data.get("is_aoe", projectile_aoe_enabled))
	projectile_aoe_radius = maxf(20.0, float(data.get("aoe_radius", projectile_aoe_radius)))
	projectile_aoe_damage_ratio = clampf(float(data.get("aoe_damage_ratio", projectile_aoe_damage_ratio)), 0.1, 1.0)
	projectile_name = str(data.get("projectile_name", projectile_name))
	var color_arr: Array = data.get("color", []) as Array
	if color_arr.size() >= 3:
		projectile_color = Color(float(color_arr[0]), float(color_arr[1]), float(color_arr[2]), 1.0)


func _setup_generated_sprite() -> void:
	var body: ColorRect = $Body
	var sprite_path: String = _get_enemy_sprite_path()
	if not ResourceLoader.exists(sprite_path):
		body.visible = false
		return
	var tex: Texture2D = load(sprite_path) as Texture2D
	if tex == null:
		body.visible = false
		return
	body.visible = false
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "EnemySprite"
	sprite.texture = tex
	sprite.centered = true
	var enemy_scale: float = ConfigService.get_value("visual.sprite_scale.enemy", 1.8)
	var enemy_target_px: float = ConfigService.get_value("visual.target_px.enemy", 88.0)
	var enemy_side: float = maxf(float(tex.get_width()), float(tex.get_height()))
	if enemy_side > 1.0:
		enemy_scale = enemy_target_px / enemy_side
	sprite.scale = Vector2(enemy_scale, enemy_scale)
	add_child(sprite)
	_generated_sprite = sprite
	_use_generated_sprite = true


func _get_enemy_sprite_path() -> String:
	var archetype_sprite: String = str(archetype_data.get("sprite_path", ""))
	if not archetype_sprite.is_empty() and ResourceLoader.exists(archetype_sprite):
		return archetype_sprite
	return "res://assets/enemies/enemy_elite.png" if is_elite else "res://assets/enemies/enemy_basic.png"


func _get_enemy_char_base_path() -> String:
	var archetype_char_path: String = str(archetype_data.get("char_base_path", ""))
	if not archetype_char_path.is_empty():
		var east_probe: String = "%s/animations/walking-6-frames/east/frame_000.png" % archetype_char_path
		var south_probe: String = "%s/animations/walking-6-frames/south/frame_000.png" % archetype_char_path
		if ResourceLoader.exists(east_probe) or ResourceLoader.exists(south_probe):
			return archetype_char_path
	return "res://assets/characters/enemy_elite" if is_elite else "res://assets/characters/enemy_basic"


func _setup_animated_sprite() -> void:
	var base_path: String = _get_enemy_char_base_path()
	var east_path: String = "%s/animations/walking-6-frames/east/frame_000.png" % base_path
	var south_path: String = "%s/animations/walking-6-frames/south/frame_000.png" % base_path
	var has_east: bool = ResourceLoader.exists(east_path)
	var has_south: bool = ResourceLoader.exists(south_path)
	if not has_east and not has_south:
		return
	var body: ColorRect = $Body
	if body:
		body.visible = false
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.name = "EnemyAnimatedSprite"
	sprite.position = Vector2.ZERO
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	if has_east:
		# East/west only mode (new archetypes — side-scrolling movement)
		_east_west_only = true
		_add_enemy_animation_frames(frames, base_path, "walk_east", "east", 10.0)
		var west_path: String = "%s/animations/walking-6-frames/west/frame_000.png" % base_path
		if ResourceLoader.exists(west_path):
			_add_enemy_animation_frames(frames, base_path, "walk_west", "west", 10.0)
		# Also load south/north when present (legacy / elite characters)
		if has_south:
			_east_west_only = false
			for direction in ["south", "north", "west"]:
				_add_enemy_animation_frames(frames, base_path, "walk_%s" % direction, direction, 10.0)
	else:
		# South/north/east/west mode (basic/elite legacy characters)
		_east_west_only = false
		for direction in ["south", "north", "east", "west"]:
			_add_enemy_animation_frames(frames, base_path, "walk_%s" % direction, direction, 10.0)
	sprite.sprite_frames = frames
	var ref_path: String = east_path if has_east else south_path
	var ref_tex: Texture2D = load(ref_path) as Texture2D
	if ref_tex != null:
		var base_target_px: float = ConfigService.get_value("visual.target_px.enemy", 88.0)
		var enemy_target_px: float = base_target_px * (1.4 if is_elite else 1.0)
		var side: float = maxf(float(ref_tex.get_width()), float(ref_tex.get_height()))
		if side > 1.0:
			sprite.scale = Vector2(enemy_target_px / side, enemy_target_px / side)
	var start_anim: String = "walk_east" if _east_west_only else "walk_south"
	sprite.play(start_anim)
	add_child(sprite)
	_animated_sprite = sprite
	_use_generated_sprite = true


func _add_enemy_animation_frames(frames: SpriteFrames, base_path: String, anim_name: String, direction: String, speed: float) -> void:
	if frames.has_animation(anim_name) and frames.get_frame_count(anim_name) > 0:
		return
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, true)
	for i in range(8):
		var path: String = "%s/animations/walking-6-frames/%s/frame_%03d.png" % [base_path, direction, i]
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex:
				frames.add_frame(anim_name, tex)
	if frames.get_frame_count(anim_name) == 0:
		var fallback_dir: String = "east" if ResourceLoader.exists("%s/animations/walking-6-frames/east/frame_000.png" % base_path) else "south"
		for i in range(8):
			var fallback_path: String = "%s/animations/walking-6-frames/%s/frame_%03d.png" % [base_path, fallback_dir, i]
			if ResourceLoader.exists(fallback_path):
				var tex: Texture2D = load(fallback_path) as Texture2D
				if tex:
					frames.add_frame(anim_name, tex)


func _update_enemy_animation(move_dir: Vector2) -> void:
	if _animated_sprite == null:
		return
	if move_dir.length_squared() < 0.01:
		return
	if _east_west_only:
		# Side-scrolling mode: use east/west based on x, flip when west animation missing
		var going_right: bool = move_dir.x >= 0.0
		var has_west_anim: bool = _animated_sprite.sprite_frames.has_animation("walk_west") \
			and _animated_sprite.sprite_frames.get_frame_count("walk_west") > 0
		if has_west_anim:
			_enemy_direction = "east" if going_right else "west"
			_animated_sprite.flip_h = false
			var walk_anim: String = "walk_%s" % _enemy_direction
			if _animated_sprite.animation != walk_anim:
				_animated_sprite.play(walk_anim)
		else:
			# Flip east animation for west movement
			_enemy_direction = "east" if going_right else "west"
			_animated_sprite.flip_h = not going_right
			if _animated_sprite.animation != "walk_east":
				_animated_sprite.play("walk_east")
	else:
		# 4-directional mode (legacy basic/elite)
		if absf(move_dir.x) > absf(move_dir.y):
			_enemy_direction = "east" if move_dir.x > 0.0 else "west"
		else:
			_enemy_direction = "south" if move_dir.y > 0.0 else "north"
		var walk_anim: String = "walk_%s" % _enemy_direction
		if _animated_sprite.sprite_frames.has_animation(walk_anim):
			if _animated_sprite.animation != walk_anim:
				_animated_sprite.play(walk_anim)


func _update_generated_sprite_texture() -> void:
	if _generated_sprite == null:
		return
	var sprite_path: String = _get_enemy_sprite_path()
	if not ResourceLoader.exists(sprite_path):
		return
	var tex: Texture2D = load(sprite_path) as Texture2D
	if tex:
		_generated_sprite.texture = tex


func _physics_process(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	_behavior_time += delta
	_fire_timer = maxf(0.0, _fire_timer - delta)
	if target and is_instance_valid(target):
		var to_target: Vector2 = target.global_position - global_position
		dir = _compute_behavior_direction(to_target)
		velocity = dir * speed * (1.0 - _chill_slow_pct)
		_try_ranged_attack(to_target)
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_update_enemy_animation(dir)
	_process_burn(delta)
	_process_chill(delta)

	# Check collision with player
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider and collider.is_in_group("player") and can_damage:
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
				can_damage = false
				damage_timer.start()


func _compute_behavior_direction(to_target: Vector2) -> Vector2:
	if to_target.length_squared() < 0.01:
		return Vector2.ZERO
	var base_dir: Vector2 = to_target.normalized()
	var dist: float = to_target.length()
	var behavior: String = str(archetype_data.get("behavior", "runner"))
	match behavior:
		"zigzag":
			var side_wave: float = sin(_behavior_time * 6.0)
			var lateral: Vector2 = base_dir.orthogonal() * side_wave * 0.55
			return (base_dir + lateral).normalized()
		"skirmisher":
			var desired_mid: float = fire_range * 0.78
			if dist < desired_mid * 0.75:
				return (-base_dir + (base_dir.orthogonal() * sin(_behavior_time * 5.5) * 0.35)).normalized()
			if dist > desired_mid * 1.25:
				return (base_dir + (base_dir.orthogonal() * sin(_behavior_time * 5.5) * 0.35)).normalized()
			return base_dir.orthogonal().normalized() * signf(sin(_behavior_time * 2.1))
		"sniper":
			if dist < fire_range * 0.65:
				return -base_dir
			if dist > fire_range * 1.15:
				return base_dir
			return Vector2.ZERO
		"mortar":
			if dist < fire_range * 0.7:
				return -base_dir
			if dist > fire_range * 1.05:
				return base_dir
			return Vector2.ZERO
		"charger":
			return base_dir * 1.1
		_:
			return base_dir


func _try_ranged_attack(to_target: Vector2) -> void:
	if not can_shoot:
		return
	if _fire_timer > 0.0:
		return
	if to_target.length() > fire_range:
		return
	if bullet_scene == null:
		return
	var shot_scene: PackedScene = aoe_bullet_scene if projectile_scene_type == "aoe" else bullet_scene
	if shot_scene == null:
		return
	var shot: Node2D = shot_scene.instantiate()
	if shot == null:
		return
	var fire_dir: Vector2 = to_target.normalized()
	shot.global_position = global_position
	if shot.has_method("set_direction"):
		shot.set_direction(fire_dir)
	if shot.has_method("set_damage"):
		shot.set_damage(maxi(1, int(round(float(damage) * projectile_damage_ratio))))
	if shot.has_method("set_damage_type"):
		shot.set_damage_type(projectile_damage_type)
	shot.speed = projectile_speed
	shot.lifetime = projectile_lifetime
	shot.weapon_type = projectile_name
	shot.target_group = "player"
	shot.modulate = projectile_color
	if projectile_aoe_enabled:
		shot.is_aoe = true
		shot.aoe_radius = projectile_aoe_radius
		shot.aoe_damage_ratio = projectile_aoe_damage_ratio
	get_tree().current_scene.add_child(shot)
	_fire_timer = fire_cooldown


func take_damage(amount: int, damage_type: String = "physical", is_crit: bool = false) -> void:
	var resist: float = 0.0
	match damage_type:
		"explosive":
			resist = explosive_resistance
		_:
			resist = physical_resistance
	resist = clampf(resist, 0.0, 0.9)
	var final_damage: int = maxi(1, int(round(float(amount) * (1.0 - resist))))
	health -= final_damage
	_spawn_damage_number(final_damage, is_crit)
	_spawn_hit_vfx()
	_update_health_bar()
	# Flash red briefly
	modulate = Color.RED
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	if health <= 0:
		died.emit(global_position)
		queue_free()


func apply_burn(amount: int, duration: float) -> void:
	_burn_damage = maxi(_burn_damage, amount)
	_burn_time_left = maxf(_burn_time_left, duration)

func apply_chill(slow_pct: float, duration: float) -> void:
	_chill_slow_pct = clampf(maxf(_chill_slow_pct, slow_pct), 0.0, 0.85)
	_chill_time_left = maxf(_chill_time_left, duration)
	var blue: Color = Color(0.55, 0.8, 1.2, 1.0)
	modulate = modulate.lerp(blue, 0.4)

func apply_freeze(duration: float) -> void:
	_chill_slow_pct = 0.99
	_chill_time_left = maxf(_chill_time_left, duration)
	modulate = Color(0.4, 0.85, 1.0, 1.0)

func _process_chill(delta: float) -> void:
	if _chill_time_left <= 0.0:
		if _chill_slow_pct > 0.0:
			_chill_slow_pct = 0.0
			modulate = Color.WHITE
		return
	_chill_time_left -= delta
	if _chill_time_left <= 0.0:
		_chill_slow_pct = 0.0
		modulate = Color.WHITE


func _process_burn(delta: float) -> void:
	if _burn_time_left <= 0.0 or health <= 0:
		return
	_burn_time_left -= delta
	_burn_tick_accumulator += delta
	while _burn_tick_accumulator >= 1.0 and _burn_time_left > -1.0 and health > 0:
		_burn_tick_accumulator -= 1.0
		take_damage(_burn_damage, "explosive", false)


func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = maxi(health, 0)
	if health_label:
		health_label.text = "%d/%d" % [maxi(health, 0), max_health]


func _draw() -> void:
	if _use_generated_sprite or _animated_sprite != null:
		return
	var body_color: Color = Color(0.85, 0.15, 0.55) if is_elite else Color(0.9, 0.22, 0.22)
	var radius: float = 14.0 if is_elite else 10.0
	# Outer glow
	draw_circle(Vector2.ZERO, radius + 5, Color(body_color.r, body_color.g, body_color.b, 0.1))
	draw_circle(Vector2.ZERO, radius + 3, Color(body_color.r, body_color.g, body_color.b, 0.2))
	# Main body
	draw_circle(Vector2.ZERO, radius, body_color)
	# Inner ring
	draw_arc(Vector2.ZERO, radius * 0.6, 0, TAU, 24, body_color.darkened(0.35), 1.5)
	# Eyes
	var eye_color: Color = Color(1.0, 0.2, 0.9) if is_elite else Color(1.0, 0.85, 0.1)
	draw_circle(Vector2(-3, -2), 2.2, eye_color)
	draw_circle(Vector2(3, -2), 2.2, eye_color)
	draw_circle(Vector2(-3, -2), 1.0, Color(0.1, 0.0, 0.0))
	draw_circle(Vector2(3, -2), 1.0, Color(0.1, 0.0, 0.0))
	# Elite crown/spikes
	if is_elite:
		var spike_color: Color = Color(1.0, 0.3, 0.85)
		for i in range(5):
			var angle: float = -PI * 0.8 + (PI * 0.6 / 4.0) * float(i)
			var spike_base: Vector2 = Vector2(cos(angle), sin(angle)) * radius
			var spike_tip: Vector2 = Vector2(cos(angle), sin(angle)) * (radius + 6)
			draw_line(spike_base, spike_tip, spike_color, 2.0)


func _spawn_damage_number(amount: int, is_crit: bool = false) -> void:
	var dmg_num: Node2D = damage_number_scene.instantiate()
	dmg_num.global_position = global_position + Vector2(0, -16)
	if dmg_num.has_method("setup"):
		dmg_num.setup(amount, is_crit)
	get_tree().current_scene.add_child(dmg_num)


func _spawn_hit_vfx() -> void:
	var vfx_path: String = "res://assets/vfx/vfx_hit_spark.png"
	if not ResourceLoader.exists(vfx_path):
		return
	var tex: Texture2D = load(vfx_path) as Texture2D
	if tex == null:
		return
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	sprite.global_position = global_position + Vector2(randf_range(-6, 6), randf_range(-6, 6))
	var hit_scale: float = ConfigService.get_value("visual.sprite_scale.vfx_hit", 1.0)
	sprite.scale = Vector2(hit_scale, hit_scale)
	sprite.modulate.a = 0.9
	get_tree().current_scene.add_child(sprite)
	var tween: Tween = sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.tween_property(sprite, "scale", Vector2(hit_scale * 1.45, hit_scale * 1.45), 0.25)
	tween.chain().tween_callback(sprite.queue_free)


func _on_damage_timer_timeout() -> void:
	can_damage = true


func apply_scaling(progress_ratio: float, elite: bool, health_growth: float, speed_growth: float, damage_growth: float) -> void:
	is_elite = elite
	if elite:
		health = int(round(health * 1.9))
		speed *= 1.2
		damage = int(round(damage * 1.5))
		$Body.color = Color(0.95, 0.35, 0.95, 1)
		# Scale up animated sprite for elites
		if _animated_sprite != null:
			_animated_sprite.scale *= 1.4
	else:
		$Body.color = Color(0.9, 0.2, 0.2, 1)

	health = int(round(float(health) * (1.0 + progress_ratio * health_growth)))
	speed *= (1.0 + progress_ratio * speed_growth)
	damage = int(round(float(damage) * (1.0 + progress_ratio * damage_growth)))
	max_health = health
	_update_health_bar()
	_update_generated_sprite_texture()
	_fire_timer = randf_range(0.0, fire_cooldown)
