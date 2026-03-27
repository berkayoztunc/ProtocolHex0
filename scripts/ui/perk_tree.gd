extends Control

signal perk_selected(upgrade_id: String)

const PerkCardScene: PackedScene = preload("res://scenes/perk_card.tscn")

# ---- Tab system: current active tab ----
var _current_tab: int = 0
var _tab_buttons: Array[Button] = []

# Card spacing
const CARD_GAP := Vector2(14.0, 14.0)
const MARGIN_LEFT: float = 220.0
const MARGIN_TOP: float = 10.0
const HEADER_HEIGHT: float = 140.0
const PANEL_PAD_H: float = 50.0
const PANEL_PAD_V: float = 30.0
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
var _card_size: Vector2 = Vector2(104, 120)   # texture region native size
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
	call_deferred("_build_tree")


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
	_tab_buttons.clear()
	_scroll_offset = 0.0
	_h_scroll_offset = 0.0

	var vp_size := _get_viewport_size()

	# Panel dimensions (centered with padding)
	var panel_w := vp_size.x - PANEL_PAD_H * 2.0
	var panel_h := vp_size.y - PANEL_PAD_V * 2.0
	# Card native region size = 104×120
	_card_size = Vector2(104.0, 120.0)
	const ACTUAL_COLS := 8  # col 0..7 in layout
	var avail_w := panel_w - MARGIN_LEFT - 20.0
	var target_w := (avail_w - CARD_GAP.x * (ACTUAL_COLS - 1)) / float(ACTUAL_COLS)
	_card_scale = clampf(target_w / _card_size.x, 0.5, 1.2)
	_display_size = _card_size * _card_scale

	# ── Background (perkbg.png stretched, full viewport) ──
	var bg := TextureRect.new()
	var bg_tex := load("res://perkbg.png") as Texture2D
	if bg_tex:
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Dark full-viewport overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.05, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# ── Centered panel frame ──
	var panel_frame := Panel.new()
	panel_frame.position = Vector2(PANEL_PAD_H, PANEL_PAD_V)
	panel_frame.size = Vector2(panel_w, panel_h)
	panel_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_sb := StyleBoxFlat.new()
	frame_sb.bg_color = Color(0.04, 0.05, 0.12, 0.82)
	frame_sb.border_color = Color(0.3, 0.4, 0.7, 0.80)
	frame_sb.set_border_width_all(2)
	frame_sb.set_corner_radius_all(8)
	frame_sb.corner_detail = 6
	panel_frame.add_theme_stylebox_override("panel", frame_sb)
	add_child(panel_frame)

	# ── Header (title, points, hint, tabs) ──
	_build_header(PANEL_PAD_H, PANEL_PAD_V, panel_w)

	# ── Clip region for scrollable content ──
	_clip_region = Control.new()
	_clip_region.clip_contents = true
	_clip_region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip_region.position = Vector2(PANEL_PAD_H, PANEL_PAD_V + HEADER_HEIGHT)
	_clip_region.size = Vector2(panel_w, panel_h - HEADER_HEIGHT)
	add_child(_clip_region)

	# ── Scrollable content ──
	_content_root = Node2D.new()
	_clip_region.add_child(_content_root)

	# Line drawer
	_draw_node = Node2D.new()
	_content_root.add_child(_draw_node)

	# Get layout/categories from UpgradeCatalogs for current tab
	var current_layout: Dictionary = UpgradeCatalogs.get_tab_layout(_current_tab)
	var current_categories: Dictionary = UpgradeCatalogs.get_tab_categories(_current_tab)

	var col_step := _display_size.x + CARD_GAP.x
	var row_step := _display_size.y + CARD_GAP.y
	var max_layout_col: int = 0
	var max_layout_row: int = 0
	for layout_value in current_layout.values():
		var layout_dict: Dictionary = layout_value as Dictionary
		max_layout_col = maxi(max_layout_col, int(layout_dict.get("col", 0)))
		max_layout_row = maxi(max_layout_row, int(layout_dict.get("row", 0)))

	# Category row labels — styled panel + label
	for row_idx in current_categories:
		var row_y := MARGIN_TOP + int(row_idx) * row_step
		# Background rect
		var row_bg := ColorRect.new()
		row_bg.color = Color(0.08, 0.10, 0.22, 0.80)
		row_bg.position = Vector2(4, row_y + 2)
		row_bg.size = Vector2(MARGIN_LEFT - 10, _display_size.y - 4)
		row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_root.add_child(row_bg)
		# Right-side accent line
		var accent := ColorRect.new()
		accent.color = Color(0.45, 0.60, 1.0, 0.55)
		accent.position = Vector2(MARGIN_LEFT - 7, row_y + 2)
		accent.size = Vector2(3, _display_size.y - 4)
		accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_root.add_child(accent)
		# Text label
		var lbl := Label.new()
		lbl.text = current_categories[row_idx]
		lbl.position = Vector2(8, row_y + (_display_size.y - 36) * 0.5)
		lbl.size = Vector2(MARGIN_LEFT - 18, 36)
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_root.add_child(lbl)

	# ── Build perk cards ──
	for perk_id in current_layout:
		if not _upgrade_catalog.has(perk_id):
			continue
		var layout: Dictionary = current_layout[perk_id]
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
		card.scale = Vector2(_card_scale, _card_scale)
		_content_root.add_child(card)
		card.setup(perk_id, perk_data, stacks, max_stacks, prereqs_met, selectable)
		card.pressed.connect(_on_card_pressed)
		_cards[perk_id] = card

		# Prerequisite connection lines
		for prereq_id in prereqs:
			if current_layout.has(str(prereq_id)):
				var pl: Dictionary = current_layout[str(prereq_id)]
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
	_max_h_scroll = maxf(0.0, content_w - panel_w)

	# Draw connection lines
	_draw_node.draw.connect(_on_draw_connections)
	_draw_node.queue_redraw()


func _build_header(panel_x: float, panel_y: float, panel_w: float) -> void:
	var header := Control.new()
	header.position = Vector2(panel_x, panel_y)
	header.size = Vector2(panel_w, HEADER_HEIGHT)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var title := Label.new()
	title.text = "◆ PERK TREE ◆"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 6)
	title.size = Vector2(panel_w, 34)
	title.add_theme_font_size_override("font_size", 26)
	header.add_child(title)

	var pts := Label.new()
	pts.text = "★ Available Perk Points: %d" % _available_points
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pts.position = Vector2(0, 42)
	pts.size = Vector2(panel_w, 28)
	pts.add_theme_font_size_override("font_size", 20)
	header.add_child(pts)

	var hint := Label.new()
	hint.text = "[P / ESC] Close  ·  Wheel: vertical · Shift+Wheel: horizontal · Left click+drag: pan"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 72)
	hint.size = Vector2(panel_w, 18)
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(0.75, 0.8, 1.0, 0.85)
	header.add_child(hint)

	# ── Tab buttons ──
	var tab_names: Dictionary = UpgradeCatalogs.TAB_NAMES
	var tab_colors: Dictionary = UpgradeCatalogs.TAB_COLORS
	var tab_count := tab_names.size()
	var btn_w := floorf(panel_w / float(tab_count))
	var btn_h := 36.0
	var tab_y := HEADER_HEIGHT - btn_h - 2.0
	for tab_id in tab_names:
		var btn := Button.new()
		btn.text = tab_names[tab_id]
		btn.position = Vector2(int(tab_id) * btn_w, tab_y)
		btn.size = Vector2(btn_w, btn_h)
		btn.add_theme_font_size_override("font_size", 13)
		var tab_col: Color = tab_colors.get(tab_id, Color.WHITE)
		if int(tab_id) == _current_tab:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			var sb := StyleBoxFlat.new()
			sb.bg_color = tab_col.darkened(0.3)
			sb.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("normal", sb)
			btn.add_theme_stylebox_override("hover", sb)
			btn.add_theme_stylebox_override("pressed", sb)
			btn.add_theme_stylebox_override("focus", sb)
		else:
			btn.modulate = Color(0.6, 0.6, 0.6, 0.9)
		btn.pressed.connect(_on_tab_pressed.bind(int(tab_id)))
		header.add_child(btn)
		_tab_buttons.append(btn)

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

	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var clip_rect_t := Rect2(_clip_region.global_position, _clip_region.size)
		var in_clip_t := clip_rect_t.has_point(touch.position)
		if touch.pressed:
			if in_clip_t:
				_is_dragging = true
				_last_mouse_pos = touch.position
				_drag_motion = 0.0
				accept_event()
		else:
			if _is_dragging:
				_is_dragging = false
				var was_tap := _drag_motion <= CLICK_DRAG_THRESHOLD
				if was_tap and in_clip_t:
					_handle_click(touch.position)
					accept_event()

	elif event is InputEventScreenDrag and _is_dragging:
		var drag := event as InputEventScreenDrag
		var delta := drag.position - _last_mouse_pos
		_drag_motion += delta.length()
		_h_scroll_offset = clampf(_h_scroll_offset - delta.x, 0.0, _max_h_scroll)
		_scroll_offset = clampf(_scroll_offset - delta.y, 0.0, _max_scroll)
		_apply_scroll()
		_last_mouse_pos = drag.position
		accept_event()


# ---------- input ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_P or event.physical_keycode == KEY_ESCAPE:
			queue_free()
			get_tree().paused = false
			get_viewport().set_input_as_handled()


func _handle_click(click_pos: Vector2) -> void:
	if _clip_region == null or _content_root == null:
		return
	# Only process clicks inside the scroll area
	var clip_rect := Rect2(_clip_region.global_position, _clip_region.size)
	if not clip_rect.has_point(click_pos):
		return
	# Convert to _content_root local space — reliable regardless of scroll/CanvasLayer
	var local_click: Vector2 = _content_root.to_local(click_pos)
	for perk_id in _cards:
		var card: PerkCard = _cards[perk_id]
		var hit_rect := Rect2(card.position - _display_size * 0.5, _display_size)
		if hit_rect.has_point(local_click):
			if card.is_selectable:
				perk_selected.emit(perk_id)
				get_viewport().set_input_as_handled()
			else:
				card._play_disabled_feedback()
			return


func _on_card_pressed(perk_id: String) -> void:
	perk_selected.emit(perk_id)


func _on_tab_pressed(tab_id: int) -> void:
	if tab_id == _current_tab:
		return
	_current_tab = tab_id
	_build_tree()
