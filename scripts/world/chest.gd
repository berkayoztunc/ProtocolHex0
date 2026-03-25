extends Node2D

signal opened(pos: Vector2)

const CONTACT_TO_OPEN: float = 3.0

var collected: bool = false
var _pulse_time: float = 0.0
var _generated_sprite: Sprite2D = null
var _use_generated_sprite: bool = false
var _player_in_contact: bool = false
var _contact_elapsed: float = 0.0
var _label: Label = null


func _ready() -> void:
	$Area2D.add_to_group("chests")
	$Area2D.collision_mask = 1  # player is on layer 1
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	_setup_contact_label()
	_setup_generated_sprite()


func _setup_contact_label() -> void:
	_label = Label.new()
	_label.name = "ContactLabel"
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 1.0))
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-40.0, -56.0)
	_label.size = Vector2(80.0, 20.0)
	_label.text = "SANDIK"
	add_child(_label)


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
	var chest_target_px: float = ConfigService.get_value("visual.target_px.chest", 90.0)
	var chest_side: float = maxf(float(tex.get_width()), float(tex.get_height()))
	if chest_side > 1.0:
		chest_scale = chest_target_px / chest_side
	sprite.scale = Vector2(chest_scale, chest_scale)
	add_child(sprite)
	_generated_sprite = sprite
	_use_generated_sprite = true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_contact = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_contact = false
		_contact_elapsed = 0.0


func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()

	if _player_in_contact and not collected:
		_contact_elapsed += delta
		var remaining: float = CONTACT_TO_OPEN - _contact_elapsed
		if remaining <= 0.0:
			collect()
		else:
			if _label != null:
				_label.text = "%.1fs" % remaining
	else:
		if _label != null:
			_label.text = "SANDIK"


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
	# Progress arc when player is opening
	if _player_in_contact and _contact_elapsed > 0.0:
		var pct: float = clampf(_contact_elapsed / CONTACT_TO_OPEN, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 16.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 24, Color(1.0, 0.88, 0.2, 0.9), 2.5)
