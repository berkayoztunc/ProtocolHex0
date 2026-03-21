extends Node2D

signal opened(pos: Vector2)

var collected: bool = false
var _pulse_time: float = 0.0
var _generated_sprite: Sprite2D = null
var _use_generated_sprite: bool = false


func _ready() -> void:
	$Area2D.add_to_group("chests")
	_setup_generated_sprite()


func _setup_generated_sprite() -> void:
	var base_sprite: ColorRect = $Sprite
	var sprite_path: String = "res://assets/pickups/chest_closed.png"
	if not ResourceLoader.exists(sprite_path):
		base_sprite.visible = false
		return
	var tex: Texture2D = load(sprite_path) as Texture2D
	if tex == null:
		base_sprite.visible = false
		return
	base_sprite.visible = false
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "ChestSprite"
	sprite.texture = tex
	sprite.centered = true
	var chest_scale: float = ConfigService.get_value("visual.sprite_scale.chest", 1.8)
	var chest_target_px: float = ConfigService.get_value("visual.target_px.chest", 58.0)
	var chest_side: float = maxf(float(tex.get_width()), float(tex.get_height()))
	if chest_side > 1.0:
		chest_scale = chest_target_px / chest_side
	sprite.scale = Vector2(chest_scale, chest_scale)
	add_child(sprite)
	_generated_sprite = sprite
	_use_generated_sprite = true


func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()


func collect() -> void:
	if collected:
		return
	collected = true
	opened.emit(global_position)
	queue_free()


func _draw() -> void:
	if _use_generated_sprite:
		return
	var gold: Color = Color(0.95, 0.78, 0.22)
	var dark: Color = Color(0.22, 0.14, 0.06)
	var pulse: float = 0.5 + 0.5 * sin(_pulse_time * 2.5)
	var glow: Color = Color(gold.r, gold.g, gold.b, 0.12 + pulse * 0.1)
	# Glow
	draw_circle(Vector2.ZERO, 14, glow)
	draw_circle(Vector2.ZERO, 12, Color(gold.r, gold.g, gold.b, 0.18 + pulse * 0.08))
	# Chest body (rounded rect approximation)
	var body_rect: Rect2 = Rect2(Vector2(-9, -5), Vector2(18, 12))
	draw_rect(body_rect, dark, true)
	draw_rect(body_rect, gold, false, 1.5)
	# Lid
	var lid_rect: Rect2 = Rect2(Vector2(-9, -8), Vector2(18, 5))
	draw_rect(lid_rect, dark.lightened(0.15), true)
	draw_rect(lid_rect, gold, false, 1.5)
	# Lock
	draw_circle(Vector2(0, -2), 2.5, gold)
	draw_circle(Vector2(0, -2), 1.5, dark)
	# Corner studs
	for sx in [-8, 7]:
		draw_circle(Vector2(sx, 3), 1.5, gold)
	# Highlight strip on lid
	draw_line(Vector2(-7, -7), Vector2(7, -7), Color(1.0, 1.0, 0.8, 0.45), 1.0)
