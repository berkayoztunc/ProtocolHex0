extends Control

const SLOT_FRAME_PATH := "res://assets/ui/panels/slot_frame_active.png"
const SLOT_SIZE := 128
const FRAME_TEX_SIZE := 64
const CD_FADE_IN  := 0.08
const CD_FADE_OUT := 0.15
const CD_ALPHA    := 0.62

# Frame tint colors for each card state
const COLOR_HELD_FRAME    := Color(1.00, 0.88, 0.20, 1.0)   # Gold: currently firing weapon
const COLOR_ACTIVE_FRAME  := Color(0.80, 0.88, 1.00, 1.0)   # Cool blue-white: slotted, not active
const COLOR_PASSIVE_FRAME := Color(0.45, 0.50, 0.62, 0.82)  # Dim: passive weapon

@onready var active_container:  HBoxContainer = $VBox/ActiveRow
@onready var passive_container: HBoxContainer = $VBox/PassiveRow

# weapon_id -> card Control (kept alive between updates for smooth tweens)
var _card_map: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func update_weapons(weapons_data: Array) -> void:
	var seen: Array[String] = []
	var has_any: bool = false

	for entry in weapons_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var weapon: Dictionary = entry as Dictionary
		var wid: String = str(weapon.get("id", "")).to_lower().replace(" ", "_")
		var key_text: String = str(weapon.get("key", ""))
		var is_held: bool = bool(weapon.get("is_held", false))
		var is_active: bool = not key_text.is_empty() or is_held
		var is_ready: bool = bool(weapon.get("ready", true))
		seen.append(wid)
		has_any = true

		if _card_map.has(wid):
			_tween_cooldown(_card_map[wid], is_ready)
			_update_held_highlight(_card_map[wid], is_held)
			# Keep held weapon first in the row
			if is_held and active_container.get_child_count() > 0:
				if active_container.get_child(0) != _card_map[wid]:
					active_container.move_child(_card_map[wid], 0)
		else:
			var card := _create_weapon_card(weapon, is_active, is_held)
			_card_map[wid] = card
			if is_active:
				active_container.add_child(card)
				if is_held:
					active_container.move_child(card, 0)
			else:
				passive_container.add_child(card)

	# Remove stale cards
	for old_id: String in _card_map.keys():
		if not seen.has(old_id):
			_card_map[old_id].queue_free()
			_card_map.erase(old_id)

	visible = has_any


func _update_held_highlight(card: Control, is_held: bool) -> void:
	var frame: Sprite2D = card.get_node_or_null("Frame") as Sprite2D
	if frame == null:
		return
	var target: Color = COLOR_HELD_FRAME if is_held else COLOR_ACTIVE_FRAME
	if not frame.modulate.is_equal_approx(target):
		frame.modulate = target


func _tween_cooldown(card: Control, is_ready: bool) -> void:
	var dim: ColorRect = card.get_node_or_null("CooldownDim") as ColorRect
	if dim == null:
		return
	var target: float = 0.0 if is_ready else CD_ALPHA
	if absf(dim.color.a - target) < 0.01:
		return
	var duration: float = CD_FADE_OUT if is_ready else CD_FADE_IN
	var tw: Tween = create_tween()
	tw.tween_property(dim, "color:a", target, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


func _create_weapon_card(weapon: Dictionary, is_active: bool, is_held: bool) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)

	# Sprite2D: slot frame scaled to SLOT_SIZE
	var frame := Sprite2D.new()
	frame.name = "Frame"
	var frame_tex: Texture2D = _load_tex(SLOT_FRAME_PATH)
	if frame_tex != null:
		frame.texture = frame_tex
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.centered = true
	frame.scale = Vector2.ONE * (float(SLOT_SIZE) / float(FRAME_TEX_SIZE))
	frame.position = Vector2(SLOT_SIZE * 0.5, SLOT_SIZE * 0.5)
	if not is_active:
		frame.modulate = COLOR_PASSIVE_FRAME
	elif is_held:
		frame.modulate = COLOR_HELD_FRAME
	else:
		frame.modulate = COLOR_ACTIVE_FRAME
	root.add_child(frame)

	# Sprite2D: weapon icon
	var wid: String = str(weapon.get("id", "")).to_lower().replace(" ", "_")
	var icon_tex: Texture2D = _load_tex("res://assets/ui/icons/weapon_%s.png" % wid)
	if icon_tex != null:
		var icon := Sprite2D.new()
		icon.name = "Icon"
		icon.texture = icon_tex
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.centered = true
		icon.position = Vector2(SLOT_SIZE * 0.5, SLOT_SIZE * 0.5)
		var tex_size: Vector2 = icon_tex.get_size()
		var s: float = (SLOT_SIZE * 0.55) / maxf(tex_size.x, tex_size.y)
		icon.scale = Vector2(s, s)
		if not is_active:
			icon.modulate = Color(0.65, 0.65, 0.70, 1.0)
		root.add_child(icon)

	# Key label (bottom-left corner) — shows which key activates this weapon
	var key_text: String = str(weapon.get("key", ""))
	var key_num: String = key_text.strip_edges().trim_prefix("[").trim_suffix("]")
	if not key_num.is_empty():
		var key_label := Label.new()
		key_label.name = "KeyLabel"
		key_label.text = key_num
		key_label.add_theme_font_size_override("font_size", 24)
		key_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.35, 1.0))
		key_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
		key_label.add_theme_constant_override("shadow_offset_x", 1)
		key_label.add_theme_constant_override("shadow_offset_y", 1)
		key_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		key_label.offset_left   = 5.0
		key_label.offset_bottom = -5.0
		key_label.offset_top    = -34.0
		key_label.offset_right  = 34.0
		root.add_child(key_label)

	# Cooldown overlay — always present on active cards, starts transparent
	if is_active:
		var dim := ColorRect.new()
		dim.name = "CooldownDim"
		dim.color = Color(0.0, 0.0, 0.0, 0.0)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(dim)
		# If already on cooldown at creation, fade in immediately
		if not bool(weapon.get("ready", true)):
			var tw: Tween = create_tween()
			tw.tween_property(dim, "color:a", CD_ALPHA, CD_FADE_IN) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	return root


func _load_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
