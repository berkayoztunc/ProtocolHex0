extends Area2D
## Static map pickup for zone-specific task items (source: "map").
## Placed at a fixed position at run start; grants the full required count when collected.
## Also used for physical enemy loot drops (required_count = 1 per drop).

signal picked_up(item_type: String)

var item_type: String = "power_shards"
var required_count: int = 1
var _collected: bool = false
var _bob_offset: float = 0.0
var _bob_speed: float = 1.2
var _bob_amplitude: float = 5.0
var _base_y: float = 0.0
var _item_tex: Texture2D = null

const TYPE_COLORS: Dictionary = {
	"nano_cores":   Color(0.3, 0.8, 1.0),
	"energy_cells": Color(1.0, 0.9, 0.1),
	"power_shards": Color(0.5, 1.0, 0.3),
	"data_cores":   Color(1.0, 0.4, 0.8),
}

const TYPE_LABELS: Dictionary = {
	"nano_cores":   "Nano Çekirdek",
	"energy_cells": "Enerji Hücresi",
	"power_shards": "Güç Kırığı",
	"data_cores":   "Veri Çekirdeği",
}

const TYPE_SPRITES: Dictionary = {
	"nano_cores":   "res://assets/pickups/loot_nano_core.png",
	"energy_cells": "res://assets/pickups/loot_energy_cell.png",
}


func _ready() -> void:
	add_to_group("zone_item_pickups")
	collision_layer = 8   # pickup layer (layer 4)
	collision_mask = 1    # detect player layer (layer 1)
	_base_y = position.y
	var col_shape: CollisionShape2D = $CollisionShape2D
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 22.0
	col_shape.shape = shape
	body_entered.connect(_on_body_entered)
	# Load sprite if available for this item type
	var spr_path: String = TYPE_SPRITES.get(item_type, "") as String
	if spr_path != "" and ResourceLoader.exists(spr_path):
		_item_tex = load(spr_path) as Texture2D
	queue_redraw()


func _process(delta: float) -> void:
	if _collected:
		return
	_bob_offset += _bob_speed * delta
	position.y = _base_y + sin(_bob_offset) * _bob_amplitude
	queue_redraw()


func _draw() -> void:
	var col: Color = TYPE_COLORS.get(item_type, Color(1.0, 1.0, 1.0)) as Color
	# Outer glow rings (always drawn)
	draw_circle(Vector2.ZERO, 26.0, Color(col.r, col.g, col.b, 0.12))
	draw_circle(Vector2.ZERO, 22.0, Color(col.r, col.g, col.b, 0.20))
	if _item_tex != null:
		# Draw PixelLab sprite centered
		var sz: Vector2 = _item_tex.get_size()
		draw_texture_rect(_item_tex, Rect2(-sz * 0.5, sz), false)
	else:
		# Fallback: hexagon body
		var pts: PackedVector2Array = PackedVector2Array()
		for i in 6:
			var a: float = (TAU / 6.0) * float(i) - PI / 6.0
			pts.append(Vector2(cos(a) * 15.0, sin(a) * 15.0))
		draw_colored_polygon(pts, col)
		# Inner darker hexagon for depth
		var inner_pts: PackedVector2Array = PackedVector2Array()
		for i in 6:
			var a: float = (TAU / 6.0) * float(i) - PI / 6.0
			inner_pts.append(Vector2(cos(a) * 8.0, sin(a) * 8.0))
		draw_colored_polygon(inner_pts, col.darkened(0.5))
	# Count + label text
	var font: Font = ThemeDB.fallback_font
	if font != null:
		var count_str: String = "x%d" % required_count
		draw_string(font, Vector2(-9.0, 5.0), count_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 1.0, 1.0, 0.95))
		var label: String = TYPE_LABELS.get(item_type, item_type) as String
		draw_string(font, Vector2(-22.0, 28.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.9, 0.9, 0.9, 0.9))


func collect() -> void:
	if _collected:
		return
	_collected = true
	picked_up.emit(item_type)
	_spawn_collect_vfx()
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


func _spawn_collect_vfx() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var col: Color = TYPE_COLORS.get(item_type, Color.WHITE) as Color
	# Expanding ring
	var ring: Line2D = Line2D.new()
	ring.z_index = 9
	for p in 28:
		var ang: float = (TAU / 28.0) * float(p)
		ring.add_point(Vector2(cos(ang), sin(ang)) * 1.0)
	ring.closed = true
	ring.width = 2.5
	ring.default_color = col
	scene_root.add_child(ring)
	ring.global_position = global_position
	var tw_ring: Tween = ring.create_tween().set_parallel(true)
	tw_ring.tween_property(ring, "scale", Vector2(18.0, 18.0), 0.38).set_ease(Tween.EASE_OUT)
	tw_ring.tween_property(ring, "modulate:a", 0.0, 0.38).set_ease(Tween.EASE_IN)
	tw_ring.chain().tween_callback(ring.queue_free)
	# Sparkle burst
	for i in 12:
		var dot: ColorRect = ColorRect.new()
		dot.z_index = 10
		dot.color = Color(col.r, col.g, col.b, 0.95)
		var r: float = randf_range(2.0, 5.0)
		dot.size = Vector2(r * 2.0, r * 2.0)
		var spark_angle: float = randf_range(0.0, TAU)
		var spd: float = randf_range(90.0, 220.0)
		var vel: Vector2 = Vector2(cos(spark_angle), sin(spark_angle)) * spd
		dot.position = global_position + Vector2(-r, -r)
		scene_root.add_child(dot)
		var dur: float = randf_range(0.25, 0.55)
		var tw: Tween = dot.create_tween().set_parallel(true)
		tw.tween_property(dot, "position", dot.position + vel * dur, dur) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(dot, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(dot.queue_free)
	# Floating item name label
	var lbl: Label = Label.new()
	lbl.text = TYPE_LABELS.get(item_type, item_type) as String
	lbl.z_index = 11
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", col)
	lbl.position = global_position + Vector2(-30.0, -18.0)
	scene_root.add_child(lbl)
	var tw3: Tween = lbl.create_tween().set_parallel(true)
	tw3.tween_property(lbl, "position:y", lbl.position.y - 55.0, 0.80).set_ease(Tween.EASE_OUT)
	tw3.tween_property(lbl, "modulate:a", 0.0, 0.80).set_ease(Tween.EASE_IN)
	tw3.chain().tween_callback(lbl.queue_free)


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body.is_in_group("player"):
		collect()
