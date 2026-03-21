extends Control

const UiTextureUtils = preload("res://scripts/ui/ui_texture_utils.gd")

signal perk_selected(upgrade_id: String)

# Layout: category -> row, col positions for each perk
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

const NODE_WIDTH: int = 180
const NODE_HEIGHT: int = 76
const COL_GAP: int = 22
const ROW_GAP: int = 16
const MARGIN_LEFT: int = 220
const MARGIN_TOP: int = 80

const RARITY_COLORS: Dictionary = {
	"common": Color(0.7, 0.7, 0.7),
	"uncommon": Color(0.3, 0.9, 0.3),
	"rare": Color(0.3, 0.5, 1.0),
	"epic": Color(0.7, 0.3, 1.0),
	"legendary": Color(1.0, 0.7, 0.1)
}

var _upgrade_stacks: Dictionary = {}
var _upgrade_catalog: Dictionary = {}
var _perk_nodes: Dictionary = {}  # perk_id -> Control
var _connection_lines: Array[Dictionary] = []
var _draw_node: Node2D = null
var _available_points: int = 0
var _selectable_ids: Dictionary = {}
var _layout_scale: float = 1.0
var _node_width: float = NODE_WIDTH
var _node_height: float = NODE_HEIGHT
var _col_gap: float = COL_GAP
var _row_gap: float = ROW_GAP
var _margin_left: float = MARGIN_LEFT
var _content_top: float = 108.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func refresh(stacks: Dictionary, catalog: Dictionary, available_points: int = 0, selectable_ids: Array[String] = []) -> void:
	_upgrade_stacks = stacks
	_upgrade_catalog = catalog
	_available_points = available_points
	_selectable_ids.clear()
	for perk_id in selectable_ids:
		_selectable_ids[str(perk_id)] = true
	_build_tree()


func _get_safe_viewport_size() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		return viewport.get_visible_rect().size
	var tree: SceneTree = get_tree()
	if tree != null and tree.root != null:
		return tree.root.get_visible_rect().size
	return Vector2(1920.0, 1080.0)


func _build_tree() -> void:
	# Clear previous
	for child in get_children():
		child.queue_free()
	_perk_nodes.clear()
	_connection_lines.clear()
	var viewport_size: Vector2 = _get_safe_viewport_size()
	_layout_scale = UiTextureUtils.get_viewport_scale(viewport_size, Vector2(1920.0, 1080.0), 0.72, 1.0)
	_node_width = UiTextureUtils.scale_dimension(float(NODE_WIDTH), _layout_scale, 2, 136.0)
	_node_height = UiTextureUtils.scale_dimension(float(NODE_HEIGHT), _layout_scale, 2, 62.0)
	_col_gap = UiTextureUtils.scale_dimension(float(COL_GAP), _layout_scale, 2, 14.0)
	_row_gap = UiTextureUtils.scale_dimension(float(ROW_GAP), _layout_scale, 2, 10.0)
	_margin_left = UiTextureUtils.scale_dimension(float(MARGIN_LEFT), _layout_scale, 4, 160.0)
	_content_top = UiTextureUtils.scale_dimension(108.0, _layout_scale, 2, 88.0)

	# Background
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Title
	var title: Label = Label.new()
	title.text = "PERK AĞACI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(30.0, _layout_scale, 1, 24.0)))
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	title.position = Vector2(0, 14)
	title.size = Vector2(viewport_size.x, 50)
	add_child(title)

	# Close instruction
	var close_hint: Label = Label.new()
	close_hint.text = "[P] veya [ESC] ile kapat"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(16.0, _layout_scale, 1, 13.0)))
	close_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	close_hint.position = Vector2(0, 50)
	close_hint.size = Vector2(viewport_size.x, 26)
	add_child(close_hint)

	var points_label: Label = Label.new()
	points_label.text = "Kullanılabilir Perk Puanı: %d" % _available_points
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(18.0, _layout_scale, 1, 14.0)))
	points_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6) if _available_points > 0 else Color(0.55, 0.55, 0.55))
	points_label.position = Vector2(0, 76)
	points_label.size = Vector2(viewport_size.x, 26)
	add_child(points_label)

	# Content container (for drawing + nodes)
	var content: Control = Control.new()
	var max_row: int = 8
	var max_col: int = 8
	var content_size: Vector2 = Vector2(
		_margin_left + (max_col + 1) * (_node_width + _col_gap),
		UiTextureUtils.scale_dimension(float(MARGIN_TOP), _layout_scale, 2, 52.0) + (max_row + 1) * (_node_height + _row_gap) + UiTextureUtils.scale_dimension(40.0, _layout_scale, 2, 26.0)
	)
	content.position = Vector2(maxf(0.0, floor((viewport_size.x - content_size.x) * 0.5)), _content_top)
	content.size = Vector2(
		maxf(viewport_size.x, content_size.x),
		maxf(viewport_size.y - _content_top, content_size.y)
	)
	add_child(content)

	# Draw node for connection lines
	_draw_node = Node2D.new()
	content.add_child(_draw_node)

	# Category labels
	for row_idx in CATEGORY_LABELS:
		var cat_label: Label = Label.new()
		cat_label.text = CATEGORY_LABELS[row_idx]
		cat_label.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(14.0, _layout_scale, 1, 11.0)))
		cat_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.4))
		cat_label.position = Vector2(UiTextureUtils.scale_dimension(8.0, _layout_scale, 1, 6.0), row_idx * (_node_height + _row_gap) + _node_height * 0.3)
		cat_label.size = Vector2(_margin_left - UiTextureUtils.scale_dimension(12.0, _layout_scale, 1, 8.0), UiTextureUtils.scale_dimension(24.0, _layout_scale, 1, 20.0))
		content.add_child(cat_label)

	# Build perk nodes
	for perk_id in PERK_LAYOUT:
		if not _upgrade_catalog.has(perk_id):
			continue
		var layout: Dictionary = PERK_LAYOUT[perk_id]
		var row: int = int(layout["row"])
		var col: int = int(layout["col"])
		var pos: Vector2 = Vector2(
			_margin_left + col * (_node_width + _col_gap),
			row * (_node_height + _row_gap)
		)
		var perk_data: Dictionary = _upgrade_catalog[perk_id]
		var stacks: int = int(_upgrade_stacks.get(perk_id, 0))
		var max_stacks: int = int(ConfigService.get_value("upgrades.max_stacks.%s" % perk_id, -1))
		var prereqs: Array = perk_data.get("prerequisites", []) as Array
		var prereqs_met: bool = true
		for prereq_id in prereqs:
			if int(_upgrade_stacks.get(str(prereq_id), 0)) <= 0:
				prereqs_met = false
				break

		var is_selectable: bool = _available_points > 0 and _selectable_ids.has(perk_id)
		var node: PanelContainer = _create_perk_node(perk_id, perk_data, stacks, max_stacks, prereqs_met, is_selectable)
		node.position = pos
		content.add_child(node)
		_perk_nodes[perk_id] = node

		# Track connection lines for prerequisites
		for prereq_id in prereqs:
			if PERK_LAYOUT.has(str(prereq_id)):
				var prereq_layout: Dictionary = PERK_LAYOUT[str(prereq_id)]
				var prereq_pos: Vector2 = Vector2(
					_margin_left + int(prereq_layout["col"]) * (_node_width + _col_gap) + _node_width * 0.5,
					int(prereq_layout["row"]) * (_node_height + _row_gap) + _node_height
				)
				var target_pos: Vector2 = Vector2(
					pos.x + _node_width * 0.5,
					pos.y
				)
				_connection_lines.append({
					"from": prereq_pos,
					"to": target_pos,
					"met": prereqs_met
				})

	# Draw connections
	_draw_node.draw.connect(_on_draw_connections)
	_draw_node.queue_redraw()


func _create_perk_node(perk_id: String, perk_data: Dictionary, stacks: int, max_stacks: int, prereqs_met: bool, is_selectable: bool) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(_node_width, _node_height)
	panel.size = Vector2(_node_width, _node_height)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = str(perk_data.get("description", ""))
	panel.gui_input.connect(_on_perk_node_gui_input.bind(perk_id, is_selectable))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.24, 0.28, 0.38, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	# Try to load pixel art perk node texture; fall back to StyleBoxFlat
	var perk_node_path := "res://assets/ui/panels/perk_node_base.png"
	var tex_style: StyleBoxTexture = UiTextureUtils.load_stylebox_texture(perk_node_path, 12) if ResourceLoader.exists(perk_node_path) else null
	if tex_style != null:
		panel.add_theme_stylebox_override("panel", tex_style)
	else:
		panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(UiTextureUtils.scale_dimension(2.0, _layout_scale, 1, 1.0)))

	# Perk name
	var name_label: Label = Label.new()
	var rarity: String = str(perk_data.get("rarity", "common"))
	var rarity_color: Color = RARITY_COLORS.get(rarity, Color.WHITE)
	name_label.text = str(perk_data.get("name", perk_id))
	name_label.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(13.0, _layout_scale, 1, 10.0)))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Stack count
	var stack_label: Label = Label.new()
	stack_label.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(11.0, _layout_scale, 1, 9.0)))
	stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var is_unlocked: bool = stacks > 0
	var is_locked: bool = not prereqs_met
	var is_maxed: bool = max_stacks > 0 and stacks >= max_stacks
	var base_cost: int = int(ConfigService.get_value("upgrades.perk_costs.%s" % perk_id, 1))
	var next_cost: int = base_cost * (stacks + 1)

	if is_locked:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		stack_label.text = "🔒 💎 %d" % next_cost
		stack_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.3))
		panel.modulate = Color(0.5, 0.5, 0.5, 0.8)
	elif is_maxed:
		name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		if max_stacks == 1:
			stack_label.text = "✓ Aktif"
		else:
			stack_label.text = "✓ MAX (%d/%d)" % [stacks, max_stacks]
		stack_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	elif is_unlocked:
		name_label.add_theme_color_override("font_color", rarity_color)
		if max_stacks > 0:
			stack_label.text = "💎 %d | %d/%d" % [next_cost, stacks, max_stacks]
		elif max_stacks < 0:
			stack_label.text = "💎 %d | ×%d" % [next_cost, stacks]
		else:
			stack_label.text = "✓"
		stack_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	else:
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		if max_stacks > 0:
			stack_label.text = "💎 %d | 0/%d" % [next_cost, max_stacks]
		else:
			stack_label.text = "💎 %d" % next_cost
		stack_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	# Apply state-based tint to pixel art texture, or border overrides to flat style
	if tex_style != null:
		if is_maxed:
			tex_style.modulate_color = Color(1.0, 0.85, 0.25, 1.0)
		elif is_selectable:
			tex_style.modulate_color = Color(0.55, 1.0, 0.4, 1.0)
		elif is_unlocked and not is_locked:
			tex_style.modulate_color = Color(rarity_color.r * 0.7 + 0.3, rarity_color.g * 0.7 + 0.3, rarity_color.b * 0.7 + 0.3, 1.0)
		elif is_locked:
			tex_style.modulate_color = Color(0.45, 0.45, 0.5, 0.8)
	else:
		if is_maxed:
			style.border_color = Color(1.0, 0.78, 0.2, 1.0)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.bg_color = Color(0.12, 0.1, 0.06, 0.97)
		elif is_unlocked and not is_locked:
			style.border_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.85)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2

		if is_selectable:
			style.border_color = Color(0.55, 0.92, 0.42, 1.0)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
			style.bg_color = Color(0.12, 0.18, 0.12, 0.98)

	if is_selectable:
		name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.55))
		stack_label.text = "💎 %d — SEÇ" % next_cost
		stack_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))

	vbox.add_child(name_label)
	vbox.add_child(stack_label)

	# Description tooltip - add as a short description label
	var desc_label: Label = Label.new()
	desc_label.text = str(perk_data.get("description", ""))
	desc_label.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(8.0, _layout_scale, 1, 7.0)))
	desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	panel.add_child(vbox)
	return panel


func _on_perk_node_gui_input(event: InputEvent, perk_id: String, is_selectable: bool) -> void:
	if not is_selectable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		perk_selected.emit(perk_id)
		get_viewport().set_input_as_handled()


func _on_draw_connections() -> void:
	if _draw_node == null:
		return
	for line in _connection_lines:
		var from_pos: Vector2 = line["from"] as Vector2
		var to_pos: Vector2 = line["to"] as Vector2
		var met: bool = line["met"] as bool
		var color: Color = Color(0.3, 0.85, 0.35, 0.9) if met else Color(0.6, 0.25, 0.25, 0.6)
		var glow_color: Color = Color(color.r, color.g, color.b, 0.2)
		var base_width: float = UiTextureUtils.scale_dimension(2.0, _layout_scale, 1, 1.5)
		# Glow pass (wide soft aura)
		_draw_node.draw_line(from_pos, to_pos, glow_color, base_width * 4.0, true)
		# Core line
		_draw_node.draw_line(from_pos, to_pos, color, base_width, true)
		# Arrow head
		var dir: Vector2 = (to_pos - from_pos).normalized()
		var arrow_size: float = UiTextureUtils.scale_dimension(10.0, _layout_scale, 1, 6.0)
		var left: Vector2 = to_pos - dir * arrow_size + dir.rotated(PI * 0.7) * arrow_size * 0.6
		var right: Vector2 = to_pos - dir * arrow_size + dir.rotated(-PI * 0.7) * arrow_size * 0.6
		var glow_left: Vector2 = to_pos - dir * arrow_size * 1.2 + dir.rotated(PI * 0.7) * arrow_size * 0.8
		var glow_right: Vector2 = to_pos - dir * arrow_size * 1.2 + dir.rotated(-PI * 0.7) * arrow_size * 0.8
		# Arrow glow
		_draw_node.draw_polygon([to_pos, glow_left, glow_right], [glow_color, glow_color, glow_color])
		# Arrow core
		_draw_node.draw_polygon([to_pos, left, right], [color, color, color])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_P or event.physical_keycode == KEY_ESCAPE:
			queue_free()
			get_tree().paused = false
			get_viewport().set_input_as_handled()
