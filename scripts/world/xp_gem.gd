extends Node2D

@export var xp_value: int = 1
@export var magnet_speed: float = 300.0

var collected: bool = false
var target: Node2D = null
var _gem_color: Color = Color(0.3, 1.0, 0.3)
var _gem_scale: float = 1.0
var _bob_time: float = 0.0
var _gem_tier: String = "small"
var _generated_sprite: Sprite2D = null
var _use_generated_sprite: bool = false


func _ready() -> void:
	$Area2D.add_to_group("xp_gems")
	_setup_generated_sprite()


func _setup_generated_sprite() -> void:
	var base_sprite: ColorRect = $Sprite
	var tex_path: String = _get_gem_texture_path()
	if not ResourceLoader.exists(tex_path):
		base_sprite.visible = false
		return
	var tex: Texture2D = load(tex_path) as Texture2D
	if tex == null:
		base_sprite.visible = false
		return
	base_sprite.visible = false
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "GemSprite"
	sprite.texture = tex
	sprite.centered = true
	var pickup_scale: float = ConfigService.get_value("visual.sprite_scale.pickup", 1.6)
	var pickup_target_px: float = ConfigService.get_value("visual.target_px.pickup", 44.0)
	var pickup_side: float = maxf(float(tex.get_width()), float(tex.get_height()))
	if pickup_side > 1.0:
		pickup_scale = pickup_target_px / pickup_side
	sprite.scale = Vector2(pickup_scale, pickup_scale)
	add_child(sprite)
	_generated_sprite = sprite
	_use_generated_sprite = true


func _get_gem_texture_path() -> String:
	match _gem_tier:
		"large":
			return "res://assets/pickups/xp_gem_large.png"
		"medium":
			return "res://assets/pickups/xp_gem_medium.png"
		_:
			return "res://assets/pickups/xp_gem_small.png"


func _update_generated_gem_texture() -> void:
	if _generated_sprite == null:
		return
	var tex_path: String = _get_gem_texture_path()
	if not ResourceLoader.exists(tex_path):
		return
	var tex: Texture2D = load(tex_path) as Texture2D
	if tex:
		_generated_sprite.texture = tex


func _physics_process(delta: float) -> void:
	if collected and target and is_instance_valid(target):
		var dir: Vector2 = (target.global_position - global_position).normalized()
		position += dir * magnet_speed * delta
		if global_position.distance_to(target.global_position) < 10.0:
			queue_free()
	else:
		_bob_time += delta
		position.y += sin(_bob_time * 3.0) * 0.3
		queue_redraw()


func collect() -> void:
	if collected:
		return
	collected = true
	target = get_tree().get_first_node_in_group("player")


func set_tier(tier: String) -> void:
	match tier:
		"large":
			xp_value = 5
			_gem_color = Color(0.95, 0.8, 0.2)
			_gem_scale = 1.3
			_gem_tier = "large"
		"medium":
			xp_value = 3
			_gem_color = Color(0.3, 0.7, 1.0)
			_gem_scale = 1.15
			_gem_tier = "medium"
		_:
			xp_value = 1
			_gem_color = Color(0.3, 1.0, 0.3)
			_gem_scale = 1.0
			_gem_tier = "small"
	_update_generated_gem_texture()
	queue_redraw()


func _draw() -> void:
	if _use_generated_sprite:
		return
	var c: Color = _gem_color
	var s: float = _gem_scale * 5.0
	# Outer glow
	draw_circle(Vector2.ZERO, s + 4, Color(c.r, c.g, c.b, 0.15))
	draw_circle(Vector2.ZERO, s + 2, Color(c.r, c.g, c.b, 0.3))
	# Diamond shape (4 points)
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(0, -s * 1.4),
		Vector2(s, 0),
		Vector2(0, s * 0.8),
		Vector2(-s, 0)
	])
	draw_colored_polygon(pts, c)
	# Inner highlight
	var inner_pts: PackedVector2Array = PackedVector2Array([
		Vector2(0, -s * 0.7),
		Vector2(s * 0.35, -s * 0.15),
		Vector2(0, s * 0.1),
		Vector2(-s * 0.35, -s * 0.15)
	])
	draw_colored_polygon(inner_pts, Color(1.0, 1.0, 1.0, 0.45))
