extends Control

const ZONE_IDS: Array[String] = ["zone_1", "zone_2", "zone_3", "zone_4"]
const ZONE_COLORS: Array[Color] = [
	Color(0.2, 0.8, 0.7),   # zone_1 teal
	Color(0.9, 0.8, 0.1),   # zone_2 yellow
	Color(0.9, 0.5, 0.1),   # zone_3 orange
	Color(0.8, 0.1, 0.1),   # zone_4 red
]

const CARD_WIDTH: float = 300.0
const CARD_HEIGHT: float = 400.0
const CARD_GAP: float = 20.0
const CARD_STRIDE: float = CARD_WIDTH + CARD_GAP
const DRAG_THRESHOLD: float = 10.0

var _current_index: int = 0
var _cards: Array[Control] = []
var _cards_container: Control = null
var _drag_start_x: float = 0.0
var _drag_start_container_x: float = 0.0
var _is_dragging: bool = false
var _drag_moved: bool = false
var _tween: Tween = null

# ── build ──────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ui()
	_snap_to_index(_current_index, false)


func _build_ui() -> void:
	# Dark full-screen background
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.1, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "SECTOR SELECT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 24.0
	title.offset_bottom = 72.0
	add_child(title)

	# Cards clipping viewport area
	var clip := Control.new()
	clip.clip_contents = true
	clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	clip.offset_top = 80.0
	clip.offset_bottom = -80.0
	add_child(clip)

	# Scrollable container that holds all cards side-by-side
	_cards_container = Control.new()
	_cards_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	clip.add_child(_cards_container)

	# Build cards
	var zones: Variant = ConfigService.get_value("zones", {})
	for i in ZONE_IDS.size():
		var zone_id: String = ZONE_IDS[i]
		var zone_data: Variant = zones.get(zone_id, {}) if zones is Dictionary else {}
		var card := _build_card(i, zone_id, zone_data)
		card.position = Vector2(i * CARD_STRIDE, 0.0)
		_cards_container.add_child(card)
		_cards.append(card)

	# Left arrow
	var left_btn := _make_arrow_button("<")
	left_btn.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	left_btn.offset_left = 16.0
	left_btn.offset_right = 64.0
	left_btn.offset_top = -30.0
	left_btn.offset_bottom = 30.0
	left_btn.pressed.connect(_on_left_pressed)
	add_child(left_btn)

	# Right arrow
	var right_btn := _make_arrow_button(">")
	right_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	right_btn.offset_left = -64.0
	right_btn.offset_right = -16.0
	right_btn.offset_top = -30.0
	right_btn.offset_bottom = 30.0
	right_btn.pressed.connect(_on_right_pressed)
	add_child(right_btn)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "← Geri"
	back_btn.flat = false
	back_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back_btn.offset_left = 24.0
	back_btn.offset_right = 160.0
	back_btn.offset_top = -60.0
	back_btn.offset_bottom = -16.0
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)


func _build_card(index: int, zone_id: String, zone_data: Dictionary) -> Control:
	var zone_color: Color = ZONE_COLORS[index] if index < ZONE_COLORS.size() else Color.WHITE
	var display_name: String = zone_data.get("display_name", zone_id)
	var level_num: int = zone_data.get("level", index + 1)
	var description: String = zone_data.get("description", "")
	var required_items: Variant = zone_data.get("required_items", {})
	var req_count: int = required_items.size() if required_items is Dictionary else 0
	var unlock_requires: String = zone_data.get("unlock_requires_zone", "")
	var is_locked: bool = unlock_requires != "" and not Session.is_zone_completed(unlock_requires)

	# Root card panel
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.14, 1.0)
	style.border_color = zone_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	# Lock badge
	if is_locked:
		var lock_lbl := Label.new()
		lock_lbl.text = "🔒 LOCKED"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.7))
		lock_lbl.add_theme_font_size_override("font_size", 13)
		vbox.add_child(lock_lbl)

	# Completed badge
	if Session.is_zone_completed(zone_id):
		var done_lbl := Label.new()
		done_lbl.text = "✓ Tamamlandı"
		done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		done_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		done_lbl.add_theme_font_size_override("font_size", 13)
		vbox.add_child(done_lbl)
		style.border_color = Color(0.3, 0.9, 0.3)

	# LVL number (big)
	var lvl_lbl := Label.new()
	lvl_lbl.text = "LVL %d" % level_num
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.add_theme_font_size_override("font_size", 52)
	lvl_lbl.add_theme_color_override("font_color", zone_color)
	vbox.add_child(lvl_lbl)

	# Zone name
	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", zone_color)
	vbox.add_child(sep)

	# Description
	if description != "":
		var desc_lbl := Label.new()
		desc_lbl.text = description
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		vbox.add_child(desc_lbl)

	# Required items count
	var req_lbl := Label.new()
	req_lbl.text = "Required item types: %d" % req_count
	req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	req_lbl.add_theme_font_size_override("font_size", 12)
	req_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(req_lbl)

	# Spacer to push button down
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Enter button
	var enter_btn := Button.new()
	enter_btn.text = "Giriş →"
	enter_btn.flat = false
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = zone_color.darkened(0.35)
	btn_style.border_color = zone_color
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(6)
	btn_style.content_margin_left = 8.0
	btn_style.content_margin_right = 8.0
	btn_style.content_margin_top = 6.0
	btn_style.content_margin_bottom = 6.0
	enter_btn.add_theme_stylebox_override("normal", btn_style)
	enter_btn.add_theme_color_override("font_color", Color.WHITE)
	enter_btn.add_theme_font_size_override("font_size", 16)
	enter_btn.pressed.connect(_on_enter_pressed.bind(zone_id))
	vbox.add_child(enter_btn)

	return card


func _make_arrow_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.flat = false
	btn.add_theme_font_size_override("font_size", 24)
	return btn

# ── navigation ─────────────────────────────────────────────────────────────────

func _on_left_pressed() -> void:
	if _current_index > 0:
		_current_index -= 1
		_snap_to_index(_current_index, true)


func _on_right_pressed() -> void:
	if _current_index < ZONE_IDS.size() - 1:
		_current_index += 1
		_snap_to_index(_current_index, true)


func _snap_to_index(index: int, animated: bool) -> void:
	if _cards_container == null:
		return
	var viewport_width: float = get_viewport_rect().size.x
	var target_x: float = (viewport_width * 0.5) - (index * CARD_STRIDE) - (CARD_WIDTH * 0.5)

	if animated:
		if _tween and _tween.is_running():
			_tween.kill()
		_tween = create_tween()
		_tween.set_trans(Tween.TRANS_CUBIC)
		_tween.set_ease(Tween.EASE_OUT)
		_tween.tween_property(_cards_container, "position:x", target_x, 0.25)
	else:
		_cards_container.position.x = target_x

	# Size container to fit all cards
	_cards_container.size = Vector2(ZONE_IDS.size() * CARD_STRIDE, CARD_HEIGHT)

	# Vertically center the container in the clip area
	var clip: Control = _cards_container.get_parent() as Control
	if clip:
		var clip_height: float = clip.size.y
		_cards_container.position.y = (clip_height - CARD_HEIGHT) * 0.5

# ── drag / touch ───────────────────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mbe := event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT:
			if mbe.pressed:
				_drag_start_x = mbe.position.x
				_drag_start_container_x = _cards_container.position.x if _cards_container else 0.0
				_is_dragging = true
				_drag_moved = false
			else:
				if _is_dragging:
					_is_dragging = false
					if _drag_moved:
						_resolve_drag_release()

	elif event is InputEventMouseMotion and _is_dragging:
		var delta: float = (event as InputEventMouseMotion).position.x - _drag_start_x
		if abs(delta) > DRAG_THRESHOLD:
			_drag_moved = true
		if _drag_moved and _cards_container != null:
			_cards_container.position.x = _drag_start_container_x + delta


func _resolve_drag_release() -> void:
	if _cards_container == null:
		return
	var viewport_width: float = get_viewport_rect().size.x
	var half_card: float = CARD_WIDTH * 0.5
	# Infer which index is closest to center
	var centered_x: float = _cards_container.position.x
	var closest: int = _current_index
	var best_dist: float = INF
	for i in ZONE_IDS.size():
		var card_center: float = centered_x + i * CARD_STRIDE + half_card
		var dist: float = abs(card_center - viewport_width * 0.5)
		if dist < best_dist:
			best_dist = dist
			closest = i
	_current_index = clamp(closest, 0, ZONE_IDS.size() - 1)
	_snap_to_index(_current_index, true)

# ── actions ────────────────────────────────────────────────────────────────────

func _on_enter_pressed(zone_id: String) -> void:
	Session.set_current_zone(zone_id)
	Session.start_new_run(Session.player_name)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
