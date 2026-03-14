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
var _generated_sprite: Sprite2D = null
var _use_generated_sprite: bool = false

var damage_number_scene: PackedScene = preload("res://scenes/damage_number.tscn")

@onready var damage_timer: Timer = $DamageTimer
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel


func _ready() -> void:
	add_to_group("enemies")
	max_health = health
	damage_timer.wait_time = damage_cooldown
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	_update_health_bar()
	health_label.add_theme_font_size_override("font_size", 8)
	health_label.add_theme_color_override("font_color", Color.WHITE)
	_setup_generated_sprite()


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
	return "res://assets/enemies/enemy_elite.png" if is_elite else "res://assets/enemies/enemy_basic.png"


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
	if target and is_instance_valid(target):
		var dir: Vector2 = (target.global_position - global_position).normalized()
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_process_burn(delta)

	# Check collision with player
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider and collider.is_in_group("player") and can_damage:
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
				can_damage = false
				damage_timer.start()


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
	if _use_generated_sprite:
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
	else:
		$Body.color = Color(0.9, 0.2, 0.2, 1)

	health = int(round(float(health) * (1.0 + progress_ratio * health_growth)))
	speed *= (1.0 + progress_ratio * speed_growth)
	damage = int(round(float(damage) * (1.0 + progress_ratio * damage_growth)))
	max_health = health
	_update_health_bar()
	_update_generated_sprite_texture()
