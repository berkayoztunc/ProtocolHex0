extends Control

signal perk_selected(upgrade_id: String)

const PerkCardScene: PackedScene = preload("res://scenes/perk_card.tscn")

# ---- Layout: category -> row/col positions for each perk ----
const PERK_LAYOUT: Dictionary = {
	# Row 0 - Temel İstatistikler
	"attack_speed": {"row": 0, "col": 0},
	"weapon_damage": {"row": 0, "col": 2},
	"max_health": {"row": 0, "col": 4},
	"move_speed": {"row": 0, "col": 6},
	# Row 1 - Gelişmiş Yetenekler
	"crit_chance": {"row": 1, "col": 0},
	"cooldown_mastery": {"row": 1, "col": 1},
	"weapon_projectile": {"row": 1, "col": 2},
	"life_regen": {"row": 1, "col": 4},
	"dash": {"row": 1, "col": 6},
	"xp_magnet": {"row": 1, "col": 7},
	# Row 2 - İleri Seviye
	"pierce": {"row": 2, "col": 0},
	"burn_dot": {"row": 2, "col": 1},
	"rear_targeting": {"row": 2, "col": 2},
	"side_sweep": {"row": 2, "col": 3},
	"armor": {"row": 2, "col": 4},
	"xp_multiplier": {"row": 2, "col": 7},
	# Row 3 - Uzmanlık
	"unlock_aoe_projectile": {"row": 3, "col": 0},
	"unlock_beam_projectile": {"row": 3, "col": 1},
	"full_spread": {"row": 3, "col": 2},
	"orbital_fire": {"row": 3, "col": 3},
	"shield": {"row": 3, "col": 4},
	"luck": {"row": 3, "col": 7},
	# Row 4 - Pasif Silahlar
	"unlock_nano": {"row": 4, "col": 0},
	"unlock_tesla": {"row": 4, "col": 1},
	"unlock_scatter": {"row": 4, "col": 2},
	"unlock_orbital_sentinel": {"row": 4, "col": 3},
	"unlock_bouncing_projectile": {"row": 4, "col": 4},
	# Row 5 - Pasif Güçlendirme
	"upgrade_nano": {"row": 5, "col": 0},
	"upgrade_tesla": {"row": 5, "col": 1},
	"upgrade_scatter": {"row": 5, "col": 2},
	"upgrade_orbital": {"row": 5, "col": 3},
	# Row 6 - Aktif Silahlar
	"unlock_railgun": {"row": 6, "col": 0},
	"unlock_void": {"row": 6, "col": 1},
	"unlock_arc": {"row": 6, "col": 2},
	"unlock_phase": {"row": 6, "col": 3},
	"unlock_gravity": {"row": 6, "col": 4},
	# Row 7 - Aktif Güçlendirme
	"upgrade_railgun": {"row": 7, "col": 0},
	"upgrade_void": {"row": 7, "col": 1},
	"upgrade_arc": {"row": 7, "col": 2},
	"upgrade_phase": {"row": 7, "col": 3},
	"upgrade_gravity": {"row": 7, "col": 4},
}

const CATEGORY_LABELS: Dictionary = {
	0: "TEMEL İSTATİSTİKLER",
	1: "GELİŞMİŞ YETENEKLER",
	2: "İLERİ SEVİYE",
	3: "UZMANLIK",
	4: "PASİF SİLAHLAR",
	5: "PASİF GÜÇLENDİRME",
	6: "AKTİF SİLAHLAR",
	7: "AKTİF GÜÇLENDİRME",
}

# Card spacing
const CARD_GAP := Vector2(16.0, 16.0)
const MARGIN_LEFT: float = 150.0
const MARGIN_TOP: float = 0.0
const HEADER_HEIGHT: float = 70.0
const SCROLL_STEP: float = 40.0
const MAX_COLS: int = 9
const MAX_ROWS: int = 8
const CLICK_DRAG_THRESHOLD: float = 6.0

var _upgrade_stacks: Dictionary = {}
var _upgrade_catalog: Dictionary = {}
var _available_points: int = 0
var _selectable_ids: Dictionary = {}

var _cards: Dictionary = {}            # perk_id -> PerkCard
var _content_root: Node2D = null
var _draw_node: Node2D = null
var _clip_region: Control = null
var _connection_lines: Array[Dictionary] = []

var _scroll_offset: float = 0.0
var _max_scroll: float = 0.0
var _h_scroll_offset: float = 0.0
var _max_h_scroll: float = 0.0
var _card_size: Vector2 = Vector2(140, 180)   # texture native size
var _display_size: Vector2 = Vector2(80, 100) # actual on-screen size
var _card_scale: float = 1.0

# Drag tracking
var _is_dragging: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _drag_motion: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func refresh(stacks: Dictionary, catalog: Dictionary, available_points: int = 0, selectable_ids: Array[String] = []) -> void:
	_upgrade_stacks = stacks
	_upgrade_catalog = catalog
	_available_points = available_points
	_selectable_ids.clear()
	for pid in selectable_ids:
		_selectable_ids[str(pid)] = true
	_build_tree()


# ---------- internal helpers ----------

func _get_viewport_size() -> Vector2:
	var vp := get_viewport()
	if vp:
		return vp.get_visible_rect().size
	return Vector2(1920, 1080)


func _build_tree() -> void:
	for c in get_children():
		c.queue_free()
	_cards.clear()
	_connection_lines.clear()
	_scroll_offset = 0.0
	_h_scroll_offset = 0.0

	var vp_size := _get_viewport_size()

	# Card design size is always 140x180 (PerkCard.DESIGN_SIZE)
	_card_size = Vector2(140.0, 180.0)
	const ACTUAL_COLS := 8  # col 0..7 in layout
	var avail_w := vp_size.x - MARGIN_LEFT - 20.0
	var target_w := (avail_w - CARD_GAP.x * (ACTUAL_COLS - 1)) / float(ACTUAL_COLS)
	# Never scale up beyond 1:1, never below 0.4
	_card_scale = clampf(target_w / _card_size.x, 0.4, 1.0)
	_display_size = _card_size * _card_scale

	# ── Background (perkbg.png stretched) ──
	var bg := TextureRect.new()
	var bg_tex := load("res://perkbg.png") as Texture2D
	if bg_tex:
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Dark overlay for contrast
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.05, 0.55)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# ── Header (title, points, hint) ──
	_build_header(vp_size)

	# ── Clip region for scrollable content ──
	_clip_region = Control.new()
	_clip_region.clip_contents = true
	_clip_region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip_region.position = Vector2(0, HEADER_HEIGHT)
	_clip_region.size = Vector2(vp_size.x, vp_size.y - HEADER_HEIGHT)
	add_child(_clip_region)

	# ── Scrollable content ──
	_content_root = Node2D.new()
	_clip_region.add_child(_content_root)

	# Line drawer
	_draw_node = Node2D.new()
	_content_root.add_child(_draw_node)

	var col_step := _display_size.x + CARD_GAP.x
	var row_step := _display_size.y + CARD_GAP.y
	var max_layout_col: int = 0
	var max_layout_row: int = 0
	for layout_value in PERK_LAYOUT.values():
		var layout_dict: Dictionary = layout_value as Dictionary
		max_layout_col = maxi(max_layout_col, int(layout_dict.get("col", 0)))
		max_layout_row = maxi(max_layout_row, int(layout_dict.get("row", 0)))

	# Category row labels
	for row_idx in CATEGORY_LABELS:
		var lbl := Label.new()
		lbl.text = CATEGORY_LABELS[row_idx]
		lbl.position = Vector2(8, MARGIN_TOP + row_idx * row_step + _display_size.y * 0.35)
		lbl.size = Vector2(MARGIN_LEFT - 12, 20)
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_root.add_child(lbl)

	# ── Build perk cards ──
	for perk_id in PERK_LAYOUT:
		if not _upgrade_catalog.has(perk_id):
			continue
		var layout: Dictionary = PERK_LAYOUT[perk_id]
		var row := int(layout["row"])
		var col := int(layout["col"])
		# Card position is the CENTRE of the sprite (in display coords)
		var pos := Vector2(
			MARGIN_LEFT + col * col_step + _display_size.x * 0.5,
			MARGIN_TOP + row * row_step + _display_size.y * 0.5
		)

		var perk_data: Dictionary = _upgrade_catalog[perk_id]
		var stacks := int(_upgrade_stacks.get(perk_id, 0))
		var max_stacks := int(ConfigService.get_value("upgrades.max_stacks.%s" % perk_id, -1))
		var prereqs: Array = perk_data.get("prerequisites", []) as Array
		var prereqs_met := true
		for prereq_id in prereqs:
			if int(_upgrade_stacks.get(str(prereq_id), 0)) <= 0:
				prereqs_met = false
				break

		var selectable := _available_points > 0 and _selectable_ids.has(perk_id)

		var card: PerkCard = PerkCardScene.instantiate() as PerkCard
		card.position = pos
		_content_root.add_child(card)
		card.setup(perk_id, perk_data, stacks, max_stacks, prereqs_met, selectable)
		card.pressed.connect(_on_card_pressed)
		_cards[perk_id] = card

		# Prerequisite connection lines
		for prereq_id in prereqs:
			if PERK_LAYOUT.has(str(prereq_id)):
				var pl: Dictionary = PERK_LAYOUT[str(prereq_id)]
				var from_pos := Vector2(
					MARGIN_LEFT + int(pl["col"]) * col_step + _display_size.x * 0.5,
					MARGIN_TOP + int(pl["row"]) * row_step + _display_size.y
				)
				var to_pos := Vector2(pos.x, pos.y - _display_size.y * 0.5)
				_connection_lines.append({"from": from_pos, "to": to_pos, "met": prereqs_met})

	# Max scroll
	var content_h := MARGIN_TOP + max_layout_row * row_step + _display_size.y + 20.0
	var visible_h := _clip_region.size.y
	_max_scroll = maxf(0.0, content_h - visible_h)

	# Horizontal scroll
	var content_w := MARGIN_LEFT + max_layout_col * col_step + _display_size.x + 20.0
	_max_h_scroll = maxf(0.0, content_w - vp_size.x)

	# Draw connection lines
	_draw_node.draw.connect(_on_draw_connections)
	_draw_node.queue_redraw()


func _build_header(vp_size: Vector2) -> void:
	var header := Control.new()
	header.size = Vector2(vp_size.x, HEADER_HEIGHT)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var title := Label.new()
	title.text = "◆ PERK AĞACI ◆"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 4)
	title.size = Vector2(vp_size.x, 26)
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)

	var hint := Label.new()
	hint.text = "[P / ESC] Kapat  ·  Tekerlek: dikey · Shift+Tekerlek: yatay · Sol tık+sürükle: pan"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 28)
	hint.size = Vector2(vp_size.x, 16)
	hint.add_theme_font_size_override("font_size", 10)
	header.add_child(hint)

	var pts := Label.new()
	pts.text = "★ Kullanılabilir Perk Puanı: %d" % _available_points
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pts.position = Vector2(0, 46)
	pts.size = Vector2(vp_size.x, 20)
	pts.add_theme_font_size_override("font_size", 14)
	header.add_child(pts)

	add_child(header)


# ---------- connection-line drawing ----------

func _on_draw_connections() -> void:
	if _draw_node == null:
		return
	for line in _connection_lines:
		var from: Vector2 = line["from"]
		var to: Vector2 = line["to"]
		var met: bool = line["met"]
		var col := Color(0.6, 0.6, 0.7, 0.8) if met else Color(0.3, 0.3, 0.3, 0.5)
		_draw_node.draw_line(from, to, col, 2.0, true)
		# Arrow head
		var dir := (to - from).normalized()
		var arrow := 10.0
		var left := to - dir * arrow + dir.rotated(PI * 0.7) * arrow * 0.6
		var right := to - dir * arrow + dir.rotated(-PI * 0.7) * arrow * 0.6
		_draw_node.draw_polygon([to, left, right], [col, col, col])


# ---------- scrolling ----------

func _apply_scroll() -> void:
	if _content_root:
		_content_root.position.y = -_scroll_offset
		_content_root.position.x = -_h_scroll_offset


func _gui_input(event: InputEvent) -> void:
	if _clip_region == null:
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		var mouse_pos_global := get_global_mouse_position()
		var clip_rect := Rect2(_clip_region.global_position, _clip_region.size)
		var in_clip := clip_rect.has_point(mouse_pos_global)

		if mouse_button.pressed:
			match mouse_button.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					if not in_clip:
						return
					if Input.is_key_pressed(KEY_SHIFT):
						_h_scroll_offset = maxf(0.0, _h_scroll_offset - SCROLL_STEP)
					else:
						_scroll_offset = maxf(0.0, _scroll_offset - SCROLL_STEP)
					_apply_scroll()
					get_viewport().set_input_as_handled()
					accept_event()
				MOUSE_BUTTON_WHEEL_DOWN:
					if not in_clip:
						return
					if Input.is_key_pressed(KEY_SHIFT):
						_h_scroll_offset = minf(_max_h_scroll, _h_scroll_offset + SCROLL_STEP)
					else:
						_scroll_offset = minf(_max_scroll, _scroll_offset + SCROLL_STEP)
					_apply_scroll()
					get_viewport().set_input_as_handled()
					accept_event()
				MOUSE_BUTTON_LEFT:
					if in_clip:
						_is_dragging = true
						_last_mouse_pos = mouse_button.position
						_drag_motion = 0.0
						get_viewport().set_input_as_handled()
						accept_event()
		else:
			if mouse_button.button_index == MOUSE_BUTTON_LEFT and _is_dragging:
				_is_dragging = false
				var was_click := _drag_motion <= CLICK_DRAG_THRESHOLD
				if was_click and in_clip:
					_handle_click(mouse_pos_global)
					get_viewport().set_input_as_handled()
					accept_event()

	elif event is InputEventMouseMotion and _is_dragging:
		var motion := event as InputEventMouseMotion
		var delta := motion.position - _last_mouse_pos
		_drag_motion += delta.length()
		_h_scroll_offset = clampf(_h_scroll_offset - delta.x, 0.0, _max_h_scroll)
		_scroll_offset = clampf(_scroll_offset - delta.y, 0.0, _max_scroll)
		_apply_scroll()
		_last_mouse_pos = motion.position
		get_viewport().set_input_as_handled()
		accept_event()


# ---------- input ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_P or event.physical_keycode == KEY_ESCAPE:
			queue_free()
			get_tree().paused = false
			get_viewport().set_input_as_handled()


func _handle_click(click_pos: Vector2) -> void:
	if _clip_region == null:
		return
	# Only process clicks inside the scroll area
	var clip_rect := Rect2(_clip_region.global_position, _clip_region.size)
	if not clip_rect.has_point(click_pos):
		return
	for perk_id in _cards:
		var card: PerkCard = _cards[perk_id]
		if card.get_card_rect_global().has_point(click_pos):
			if card.is_selectable:
				perk_selected.emit(perk_id)
				get_viewport().set_input_as_handled()
			return


func _on_card_pressed(perk_id: String) -> void:
	perk_selected.emit(perk_id)
