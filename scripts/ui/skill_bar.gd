extends Control

const SLOT_FRAME_PATH := "res://assets/ui/panels/slot_frame_active.png"
const SLOT_SIZE := 128
const FRAME_TEX_SIZE := 64
const CD_ALPHA    := 0.72

# Frame tint colors for each card state
const COLOR_HELD_FRAME    := Color(1.00, 0.88, 0.20, 1.0)   # Gold: currently firing weapon
const COLOR_ACTIVE_FRAME  := Color(0.80, 0.88, 1.00, 1.0)   # Cool blue-white: slotted, not active
const COLOR_PASSIVE_FRAME := Color(0.45, 0.50, 0.62, 0.82)  # Dim: passive weapon

@onready var active_container:  HBoxContainer = $VBox/ActiveRow
@onready var passive_container: HBoxContainer = $VBox/PassiveRow

# weapon_id -> card Control (kept alive between updates for smooth tweens)
var _card_map: Dictionary = {}
var _recall_card: Control = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_recall_card()


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

		var cd_pct: float  = float(weapon.get("cooldown_pct", 0.0))
		var cd_time: float = float(weapon.get("cooldown_time", 0.0))
		if _card_map.has(wid):
			_update_cooldown(_card_map[wid], is_ready, cd_pct, cd_time)
			_update_held_highlight(_card_map[wid], is_held)
		else:
			var card := _create_weapon_card(weapon, is_active, is_held)
			_card_map[wid] = card
			if is_active:
				active_container.add_child(card)
			else:
				passive_container.add_child(card)

	# Remove stale cards
	for old_id: String in _card_map.keys():
		if not seen.has(old_id):
			_card_map[old_id].queue_free()
			_card_map.erase(old_id)

	# Keep containers sorted by fixed slot_key (matches perk tree column order)
	_sort_container_by_key(active_container)
	_sort_container_by_key(passive_container)

	visible = has_any


func _update_held_highlight(card: Control, is_held: bool) -> void:
	# Skip while flash tween is running so it isn't overwritten.
	if card.get_meta("flashing", false):
		return
	var frame: Sprite2D = card.get_node_or_null("Frame") as Sprite2D
	if frame == null:
		return
	var target: Color = COLOR_HELD_FRAME if is_held else COLOR_ACTIVE_FRAME
	if not frame.modulate.is_equal_approx(target):
		frame.modulate = target


# Updates the cooldown overlay height and countdown label.
# cooldown_pct : 1.0 = full cooldown remaining, 0.0 = ready
# cooldown_time: remaining seconds
func _update_cooldown(card: Control, is_ready: bool, cooldown_pct: float, cooldown_time: float) -> void:
	var dim: ColorRect = card.get_node_or_null("CooldownDim") as ColorRect
	var lbl: Label     = card.get_node_or_null("CooldownLabel") as Label
	var was_ready: bool = bool(card.get_meta("was_ready", true))

	if dim != null:
		if is_ready:
			dim.color.a  = 0.0
			dim.offset_top = float(SLOT_SIZE)
		else:
			dim.color.a  = CD_ALPHA
			dim.offset_top = float(SLOT_SIZE) * (1.0 - cooldown_pct)

	if lbl != null:
		if is_ready or cooldown_time <= 0.0:
			lbl.visible = false
		else:
			lbl.visible = true
			lbl.text = str(ceili(cooldown_time))

	# Cooldown just finished → flash frame yellow for ~0.9 s
	if is_ready and not was_ready and not bool(card.get_meta("flashing", false)):
		var frame: Sprite2D = card.get_node_or_null("Frame") as Sprite2D
		if frame != null:
			card.set_meta("flashing", true)
			var tw: Tween = create_tween()
			tw.tween_property(frame, "modulate", Color(1.0, 1.0, 0.3, 1.0), 0.12) \
				.set_ease(Tween.EASE_OUT)
			tw.tween_property(frame, "modulate", COLOR_ACTIVE_FRAME, 0.78) \
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			tw.tween_callback(func() -> void: card.set_meta("flashing", false))

	card.set_meta("was_ready", is_ready)


func _create_weapon_card(weapon: Dictionary, is_active: bool, is_held: bool) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	root.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	root.set_meta("was_ready", bool(weapon.get("ready", true)))
	root.set_meta("flashing", false)
	var _kt: String = str(weapon.get("key", "")).strip_edges().trim_prefix("[").trim_suffix("]")
	root.set_meta("slot_key", int(_kt) if not _kt.is_empty() else 0)

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

	# Cooldown overlay — anchored full-rect; top edge animated for progress
	if is_active:
		var cd_pct: float = float(weapon.get("cooldown_pct", 0.0))
		var is_rdy: bool = bool(weapon.get("ready", true))
		var dim := ColorRect.new()
		dim.name = "CooldownDim"
		dim.anchor_left   = 0.0
		dim.anchor_top    = 0.0
		dim.anchor_right  = 1.0
		dim.anchor_bottom = 1.0
		dim.offset_left   = 0.0
		dim.offset_right  = 0.0
		dim.offset_bottom = 0.0
		if is_rdy:
			dim.color = Color(0.0, 0.0, 0.0, 0.0)
			dim.offset_top = float(SLOT_SIZE)
		else:
			dim.color = Color(0.0, 0.0, 0.0, CD_ALPHA)
			dim.offset_top = float(SLOT_SIZE) * (1.0 - cd_pct)
		root.add_child(dim)

		# Countdown label — rendered above the dim overlay
		var cd_lbl := Label.new()
		cd_lbl.name = "CooldownLabel"
		cd_lbl.add_theme_font_size_override("font_size", 36)
		cd_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		cd_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
		cd_lbl.add_theme_constant_override("shadow_offset_x", 2)
		cd_lbl.add_theme_constant_override("shadow_offset_y", 2)
		cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		cd_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var init_cd: float = float(weapon.get("cooldown_time", 0.0))
		cd_lbl.visible = not is_rdy and init_cd > 0.0
		cd_lbl.text    = str(ceili(init_cd)) if cd_lbl.visible else ""
		root.add_child(cd_lbl)

	return root


func _sort_container_by_key(container: HBoxContainer) -> void:
	var children := container.get_children()
	children.sort_custom(func(a: Node, b: Node) -> bool:
		return int(a.get_meta("slot_key", 0)) < int(b.get_meta("slot_key", 0))
	)
	for i in range(children.size()):
		container.move_child(children[i], i)


func _load_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _build_recall_card() -> void:
	if _recall_card != null:
		return
	var root := Control.new()
	root.name = "RecallCard"
	root.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	root.clip_children = CanvasItem.CLIP_CHILDREN_ONLY

	# Frame
	var frame := Sprite2D.new()
	frame.name = "Frame"
	var frame_tex: Texture2D = _load_tex(SLOT_FRAME_PATH)
	if frame_tex != null:
		frame.texture = frame_tex
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.centered = true
	frame.scale = Vector2.ONE * (float(SLOT_SIZE) / float(FRAME_TEX_SIZE))
	frame.position = Vector2(SLOT_SIZE * 0.5, SLOT_SIZE * 0.5)
	frame.modulate = Color(0.35, 0.85, 0.45, 1.0)  # green tint = recall ready
	root.add_child(frame)

	# Key label "R"
	var key_lbl := Label.new()
	key_lbl.name = "KeyLabel"
	key_lbl.text = "R"
	key_lbl.add_theme_font_size_override("font_size", 24)
	key_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.35, 1.0))
	key_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	key_lbl.add_theme_constant_override("shadow_offset_x", 1)
	key_lbl.add_theme_constant_override("shadow_offset_y", 1)
	key_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	key_lbl.offset_left   = 5.0
	key_lbl.offset_bottom = -5.0
	key_lbl.offset_top    = -34.0
	key_lbl.offset_right  = 34.0
	root.add_child(key_lbl)

	# Recall icon: large arrow symbol centered in card
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = "↩"
	name_lbl.add_theme_font_size_override("font_size", 42)
	name_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65, 0.95))
	name_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(name_lbl)

	# Cooldown dim overlay
	var dim := ColorRect.new()
	dim.name = "CooldownDim"
	dim.anchor_left   = 0.0
	dim.anchor_top    = 0.0
	dim.anchor_right  = 1.0
	dim.anchor_bottom = 1.0
	dim.offset_left   = 0.0
	dim.offset_right  = 0.0
	dim.offset_bottom = 0.0
	dim.color = Color(0.0, 0.0, 0.0, 0.0)
	dim.offset_top = float(SLOT_SIZE)  # fully hidden when ready
	root.add_child(dim)

	# Cooldown countdown label
	var cd_lbl := Label.new()
	cd_lbl.name = "CooldownLabel"
	cd_lbl.add_theme_font_size_override("font_size", 36)
	cd_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	cd_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	cd_lbl.add_theme_constant_override("shadow_offset_x", 2)
	cd_lbl.add_theme_constant_override("shadow_offset_y", 2)
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	cd_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd_lbl.visible = false
	root.add_child(cd_lbl)

	_recall_card = root
	active_container.add_child(root)


## Called by HUD whenever recall state changes.
## state: "ready" | "cooldown" | "unavailable"
## cooldown: remaining seconds (only used when state == "cooldown")
func update_recall_state(state: String, cooldown: float = 0.0) -> void:
	if _recall_card == null:
		return
	var frame: Sprite2D = _recall_card.get_node_or_null("Frame") as Sprite2D
	var dim: ColorRect   = _recall_card.get_node_or_null("CooldownDim") as ColorRect
	var cd_lbl: Label    = _recall_card.get_node_or_null("CooldownLabel") as Label
	var max_recall_cd: float = 45.0  # matches config recall.cooldown

	match state:
		"ready":
			if frame != null:
				frame.modulate = Color(0.35, 0.85, 0.45, 1.0)  # green
			if dim != null:
				dim.color.a  = 0.0
				dim.offset_top = float(SLOT_SIZE)
			if cd_lbl != null:
				cd_lbl.visible = false
		"cooldown":
			if frame != null:
				frame.modulate = Color(1.0, 0.55, 0.1, 1.0)  # orange
			if dim != null:
				var pct: float = clampf(cooldown / max_recall_cd, 0.0, 1.0)
				dim.color = Color(0.0, 0.0, 0.0, CD_ALPHA)
				dim.offset_top = float(SLOT_SIZE) * (1.0 - pct)
			if cd_lbl != null:
				cd_lbl.visible = cooldown > 0.0
				cd_lbl.text = str(ceili(cooldown))
		"unavailable":
			if frame != null:
				frame.modulate = Color(0.4, 0.4, 0.45, 0.8)  # grey
			if dim != null:
				dim.color = Color(0.0, 0.0, 0.0, 0.5)
				dim.offset_top = 0.0
			if cd_lbl != null:
				cd_lbl.visible = false
