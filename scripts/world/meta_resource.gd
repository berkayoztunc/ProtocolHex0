extends Area2D
## Rare meta-resource drop: Scrap / Battery / Nanochips
## Dropped from enemies with 0.001 chance, picked up by player proximity.
## Collected resources go to Session.inventory (persistent cross-run).

signal resource_collected

var resource_type: String = "scrap"  # "scrap" | "battery" | "nanochips"
var _bob_offset: float = 0.0
var _bob_speed: float = 1.8
var _bob_amplitude: float = 5.0
var _base_y: float = 0.0
var _collected: bool = false

# Colors per type (matched to ConfigService)
const TYPE_COLORS: Dictionary = {
	"scrap":     Color(0.62, 0.62, 0.66),
	"battery":   Color(1.0,  0.85, 0.1),
	"nanochips": Color(0.5,  0.3,  1.0)
}

const TYPE_LABELS: Dictionary = {
	"scrap":     "SCRP",
	"battery":   "BATT",
	"nanochips": "CHIP"
}


func _ready() -> void:
	add_to_group("meta_resources")
	collision_layer = 8   # pickup layer (layer 4)
	collision_mask = 1    # detect player layer (layer 1)
	_base_y = position.y
	var col_shape: CollisionShape2D = $CollisionShape2D
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 14.0
	col_shape.shape = shape
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	if _collected:
		return
	_bob_offset += _bob_speed * delta
	position.y = _base_y + sin(_bob_offset) * _bob_amplitude
	queue_redraw()


func _draw() -> void:
	var col: Color = TYPE_COLORS.get(resource_type, Color(1.0, 1.0, 1.0)) as Color
	match resource_type:
		"scrap":
			_draw_scrap(col)
		"battery":
			_draw_battery(col)
		"nanochips":
			_draw_nanochips(col)
	# Draw type label text below the shape
	var font: Font = ThemeDB.fallback_font
	if font != null:
		var lbl: String = TYPE_LABELS.get(resource_type, "?") as String
		draw_string(font, Vector2(-10.0, 18.0), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.9, 0.9, 0.85))


func _draw_scrap(col: Color) -> void:
	# Grayish jagged irregular polygon ~7 points
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -12.0),
		Vector2(8.0, -5.0),
		Vector2(11.0, 4.0),
		Vector2(3.0, 11.0),
		Vector2(-7.0, 8.0),
		Vector2(-10.0, -2.0),
		Vector2(-4.0, -10.0)
	])
	draw_colored_polygon(pts, col)
	# Inner darker shade for depth
	var inner_pts: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -7.0),
		Vector2(4.0, -2.0),
		Vector2(5.0, 3.0),
		Vector2(0.0, 6.0),
		Vector2(-5.0, 3.0),
		Vector2(-5.0, -2.0)
	])
	draw_colored_polygon(inner_pts, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6))


func _draw_battery(col: Color) -> void:
	# Vertical rounded rectangle body
	draw_rect(Rect2(-6.0, -10.0, 12.0, 18.0), col)
	draw_rect(Rect2(-6.0, -10.0, 12.0, 18.0), Color(col.r * 0.4, col.g * 0.4, col.b * 0.4), false, 1.5)
	# Terminal nubs on top
	draw_rect(Rect2(-3.0, -14.0, 6.0, 4.0), col)
	# Inner highlight lines
	draw_line(Vector2(-4.0, -3.0), Vector2(4.0, -3.0), Color(1.0, 1.0, 1.0, 0.5), 1.5)
	draw_line(Vector2(-4.0, 1.0), Vector2(4.0, 1.0), Color(1.0, 1.0, 1.0, 0.3), 1.0)


func _draw_nanochips(col: Color) -> void:
	# 3x3 grid of small squares with connecting lines between them
	var grid_size: int = 3
	var cell: float = 6.0
	var gap: float = 3.0
	var total: float = float(grid_size) * cell + float(grid_size - 1) * gap
	var offset: Vector2 = Vector2(-total * 0.5, -total * 0.5)
	# Draw connecting lines first (under squares)
	for r in grid_size:
		for c in grid_size:
			var cx: float = offset.x + float(c) * (cell + gap) + cell * 0.5
			var cy: float = offset.y + float(r) * (cell + gap) + cell * 0.5
			if c < grid_size - 1:
				var nx: float = offset.x + float(c + 1) * (cell + gap) + cell * 0.5
				draw_line(Vector2(cx, cy), Vector2(nx, cy), Color(col.r, col.g, col.b, 0.5), 1.0)
			if r < grid_size - 1:
				var ny: float = offset.y + float(r + 1) * (cell + gap) + cell * 0.5
				draw_line(Vector2(cx, cy), Vector2(cx, ny), Color(col.r, col.g, col.b, 0.5), 1.0)
	# Draw squares on top of lines
	for r in grid_size:
		for c in grid_size:
			var rx: float = offset.x + float(c) * (cell + gap)
			var ry: float = offset.y + float(r) * (cell + gap)
			draw_rect(Rect2(rx, ry, cell, cell), col)
			draw_rect(Rect2(rx, ry, cell, cell), Color(col.r * 0.5, col.g * 0.5, col.b * 0.5), false, 1.0)


func collect() -> void:
	if _collected:
		return
	if not Session.can_pick_up():
		return
	_collected = true
	Session.add_to_inventory(resource_type)
	resource_collected.emit()
	_spawn_collect_burst()
	# Brief flash then free
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.05)
	tween.tween_interval(0.1)
	tween.tween_callback(queue_free)


func _spawn_collect_burst() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var col: Color = TYPE_COLORS.get(resource_type, Color(1.0, 1.0, 1.0)) as Color
	# Sparkle particles
	for i in 9:
		var dot: ColorRect = ColorRect.new()
		dot.z_index = 8
		dot.color = Color(minf(col.r * 1.5, 1.0), minf(col.g * 1.5, 1.0), minf(col.b * 1.5, 1.0), 0.95)
		var r: float = randf_range(1.8, 4.0)
		dot.size = Vector2(r * 2.0, r * 2.0)
		var spark_angle: float = randf_range(0.0, TAU)
		var spd: float = randf_range(65.0, 150.0)
		var vel: Vector2 = Vector2(cos(spark_angle), sin(spark_angle)) * spd
		dot.position = global_position + Vector2(-r, -r)
		scene_root.add_child(dot)
		var dur: float = randf_range(0.22, 0.48)
		var tw: Tween = dot.create_tween().set_parallel(true)
		tw.tween_property(dot, "position", dot.position + vel * dur, dur).set_ease(Tween.EASE_OUT)
		tw.tween_property(dot, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(dot.queue_free)
	# Floating +1 label
	var lbl: Label = Label.new()
	lbl.text = "+1"
	lbl.z_index = 10
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", col)
	lbl.position = global_position + Vector2(-8.0, -12.0)
	scene_root.add_child(lbl)
	var tw2: Tween = lbl.create_tween().set_parallel(true)
	tw2.tween_property(lbl, "position:y", lbl.position.y - 44.0, 0.65).set_ease(Tween.EASE_OUT)
	tw2.tween_property(lbl, "modulate:a", 0.0, 0.65).set_ease(Tween.EASE_IN)
	tw2.chain().tween_callback(lbl.queue_free)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect()
