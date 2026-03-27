extends Control
## Base Perk Upgrade screen.
## Shows all passive perks that can be permanently upgraded using meta-resources.
## Categories "passive" and "passive_active" are treated as base perks.

const BASE_PERK_MAX_LEVEL: int = 3

var _catalog: Dictionary = {}
var _scroll: ScrollContainer = null
var _grid: GridContainer = null
var _inv_label: Label = null


func _ready() -> void:
	_catalog = UpgradeCatalogs.get_all_catalogs()
	_build_ui()
	_refresh_inventory_label()


# ───────────────────────────────────────────────────────────
#  UI BUILD
# ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.07, 1.0)
	add_child(bg)

	# Margin
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(root_vbox)

	# Header row
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root_vbox.add_child(header)

	var title: Label = Label.new()
	title.text = "PERMANENT PERK UPGRADES"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_inv_label = Label.new()
	_inv_label.add_theme_font_size_override("font_size", 13)
	_inv_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	header.add_child(_inv_label)

	var sep: HSeparator = HSeparator.new()
	root_vbox.add_child(sep)

	# Scroll + grid
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_scroll)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 12)
	_scroll.add_child(_grid)

	_populate_grid()

	# Back button
	var sep2: HSeparator = HSeparator.new()
	root_vbox.add_child(sep2)

	var back_btn: Button = Button.new()
	back_btn.text = "← Back"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.custom_minimum_size = Vector2(140, 40)
	back_btn.pressed.connect(_on_back_pressed)
	root_vbox.add_child(back_btn)


func _populate_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var base_perk_ids: Array[String] = _get_base_perk_ids()
	for perk_id in base_perk_ids:
		var perk_data: Dictionary = _catalog.get(perk_id, {}) as Dictionary
		_grid.add_child(_build_perk_card(perk_id, perk_data))


func _get_base_perk_ids() -> Array[String]:
	var result: Array[String] = []
	for raw_id in _catalog.keys():
		var perk_id: String = str(raw_id)
		var data: Dictionary = _catalog[perk_id] as Dictionary
		var category: String = str(data.get("category", ""))
		if category == "passive" or category == "passive_active":
			result.append(perk_id)
	return result


func _build_perk_card(perk_id: String, perk_data: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 90)
	card.name = "Card_" + perk_id

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.12, 0.9)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.25, 0.4, 0.7)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	card.add_theme_stylebox_override("panel", style)

	var inner: MarginContainer = MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 10)
	inner.add_theme_constant_override("margin_right", 10)
	inner.add_theme_constant_override("margin_top", 8)
	inner.add_theme_constant_override("margin_bottom", 8)
	card.add_child(inner)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	inner.add_child(hbox)

	# Left: name + description + level dots
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)

	var perk_name: Label = Label.new()
	perk_name.text = str(perk_data.get("name", perk_id))
	perk_name.add_theme_font_size_override("font_size", 13)
	perk_name.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	info_vbox.add_child(perk_name)

	var perk_desc: Label = Label.new()
	perk_desc.text = str(perk_data.get("description", ""))
	perk_desc.add_theme_font_size_override("font_size", 10)
	perk_desc.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	perk_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(perk_desc)

	# Level dots
	var current_level: int = Session.get_base_perk_level(perk_id)
	var dots_row: HBoxContainer = HBoxContainer.new()
	dots_row.add_theme_constant_override("separation", 4)
	info_vbox.add_child(dots_row)
	var level_prefix: Label = Label.new()
	level_prefix.text = "Seviye:"
	level_prefix.add_theme_font_size_override("font_size", 10)
	level_prefix.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	dots_row.add_child(level_prefix)
	for i in BASE_PERK_MAX_LEVEL:
		var dot: Label = Label.new()
		dot.text = "●" if i < current_level else "○"
		dot.add_theme_font_size_override("font_size", 12)
		var dot_color: Color = Color(0.4, 0.9, 0.5) if i < current_level else Color(0.35, 0.35, 0.45)
		dot.add_theme_color_override("font_color", dot_color)
		dots_row.add_child(dot)

	# Right: cost + upgrade button
	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 4)
	right_vbox.custom_minimum_size = Vector2(160, 0)
	hbox.add_child(right_vbox)

	if current_level >= BASE_PERK_MAX_LEVEL:
		var max_lbl: Label = Label.new()
		max_lbl.text = "MAX LEVEL"
		max_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		max_lbl.add_theme_font_size_override("font_size", 11)
		max_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		right_vbox.add_child(max_lbl)
	else:
		var next_cost: Dictionary = Session.get_base_perk_upgrade_cost(perk_id)
		var cost_lbl: Label = Label.new()
		var parts: Array[String] = []
		if int(next_cost.get("scrap", 0)) > 0:
			parts.append("Hurda:%d" % int(next_cost.get("scrap", 0)))
		if int(next_cost.get("battery", 0)) > 0:
			parts.append("Btry:%d" % int(next_cost.get("battery", 0)))
		if int(next_cost.get("nanochips", 0)) > 0:
			parts.append("Chip:%d" % int(next_cost.get("nanochips", 0)))
		cost_lbl.text = "\n".join(parts) if not parts.is_empty() else "Free"
		cost_lbl.add_theme_font_size_override("font_size", 10)
		cost_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_vbox.add_child(cost_lbl)

		var can_afford: bool = _can_afford(next_cost)
		var upgrade_btn: Button = Button.new()
		upgrade_btn.text = "Upgrade"
		upgrade_btn.custom_minimum_size = Vector2(100, 30)
		upgrade_btn.add_theme_font_size_override("font_size", 11)
		upgrade_btn.disabled = not can_afford
		upgrade_btn.pressed.connect(func() -> void: _on_upgrade_pressed(perk_id))
		right_vbox.add_child(upgrade_btn)

	return card


func _can_afford(cost: Dictionary) -> bool:
	for resource in cost.keys():
		if Session.get_inventory_count(str(resource)) < int(cost[resource]):
			return false
	return true


# ───────────────────────────────────────────────────────────
#  CALLBACKS
# ───────────────────────────────────────────────────────────

func _on_upgrade_pressed(perk_id: String) -> void:
	var success: bool = Session.upgrade_base_perk(perk_id)
	if success:
		_refresh_inventory_label()
		_populate_grid()


func _refresh_inventory_label() -> void:
	if _inv_label == null:
		return
	_inv_label.text = "Hurda: %d  |  Batarya: %d  |  Nanochip: %d" % [
		Session.get_inventory_count("scrap"),
		Session.get_inventory_count("battery"),
		Session.get_inventory_count("nanochips")
	]


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
