extends CanvasLayer

const UiTextureUtils = preload("res://scripts/ui_texture_utils.gd")

signal upgrade_selected(upgrade_id: String)
signal menu_requested
signal perk_tree_requested
signal projectile_switch_requested
signal game_over_restart_requested
signal game_over_menu_requested

@onready var stats_bg_panel: PanelContainer = $StatsBGPanel
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var xp_bar: ProgressBar = $MarginContainer/VBoxContainer/XPBar
@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelLabel
@onready var kill_label: Label = $MarginContainer/VBoxContainer/StatsRow1/KillLabel
@onready var bomb_label: Label = $MarginContainer/VBoxContainer/StatsRow1/BombLabel
@onready var heal_label: Label = $MarginContainer/VBoxContainer/StatsRow2/HealLabel
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/WeaponLabel
@onready var projectile_label: Label = $MarginContainer/VBoxContainer/ProjectileLabel
@onready var targeting_label: Label = $MarginContainer/VBoxContainer/StatsRow2/TargetingLabel
@onready var modal_backdrop: ColorRect = $ModalBackdrop
@onready var level_up_panel: PanelContainer = $LevelUpPanel
@onready var level_up_title: Label = $LevelUpPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var option_button_a: Button = $LevelUpPanel/MarginContainer/VBoxContainer/OptionButtonA
@onready var option_button_b: Button = $LevelUpPanel/MarginContainer/VBoxContainer/OptionButtonB
@onready var option_button_c: Button = $LevelUpPanel/MarginContainer/VBoxContainer/OptionButtonC
@onready var confirm_menu_panel: PanelContainer = $ConfirmMenuPanel
@onready var controls_panel: PanelContainer = $ControlsPanel
@onready var menu_controls_panel: VBoxContainer = $ConfirmMenuPanel/VBox/MenuControlsPanel
@onready var active_weapons_panel: HBoxContainer = $ActiveWeaponsPanel
@onready var projectile_switch_button: Button = $TopRightContainer/ProjectileSwitchButton
@onready var perk_tree_button: Button = $TopRightContainer/PerkTreeButton
@onready var menu_button: Button = $TopRightContainer/MenuButton
@onready var top_right_container: HBoxContainer = $TopRightContainer
@onready var hud_margin: MarginContainer = $MarginContainer
@onready var hud_vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var stats_row_1: HBoxContainer = $MarginContainer/VBoxContainer/StatsRow1
@onready var stats_row_2: HBoxContainer = $MarginContainer/VBoxContainer/StatsRow2
@onready var controls_margin: MarginContainer = $ControlsPanel/MarginContainer
@onready var controls_vbox: VBoxContainer = $ControlsPanel/MarginContainer/VBoxContainer
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var game_over_title: Label = $GameOverPanel/VBox/GameOverTitle
@onready var game_over_kills_label: Label = $GameOverPanel/VBox/StatsContainer/KillsStatLabel
@onready var game_over_level_label: Label = $GameOverPanel/VBox/StatsContainer/LevelStatLabel
@onready var game_over_weapon_label: Label = $GameOverPanel/VBox/StatsContainer/WeaponStatLabel
@onready var game_over_restart_btn: Button = $GameOverPanel/VBox/RestartButton
@onready var game_over_menu_btn: Button = $GameOverPanel/VBox/MenuButton

const HUD_BAR_TEXTURE_WIDTH := 128
const HUD_BAR_STRIP_HEIGHT := 12
const HUD_BAR_SCALE := 3
const HUD_BAR_WIDTH := HUD_BAR_TEXTURE_WIDTH * HUD_BAR_SCALE
const HUD_BAR_HEIGHT := HUD_BAR_STRIP_HEIGHT * HUD_BAR_SCALE

var option_ids: Array[String] = []
var _notification_container: VBoxContainer = null
var _notification_layer: MarginContainer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var viewport: Viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_resized):
		viewport.size_changed.connect(_on_viewport_resized)
	_apply_ux_style()
	_ensure_notification_container()
	modal_backdrop.visible = false
	level_up_panel.visible = false
	confirm_menu_panel.visible = false
	menu_controls_panel.visible = false
	controls_panel.visible = false
	game_over_panel.visible = false
	option_button_a.pressed.connect(func(): _emit_option(0))
	option_button_b.pressed.connect(func(): _emit_option(1))
	option_button_c.pressed.connect(func(): _emit_option(2))
	projectile_switch_button.pressed.connect(_on_projectile_switch_button_pressed)
	game_over_restart_btn.pressed.connect(_on_game_over_restart)
	game_over_menu_btn.pressed.connect(_on_game_over_menu)
	# Compact HUD: hide redundant verbose labels
	weapon_label.visible = false
	projectile_label.visible = false
	targeting_label.visible = false
	stats_row_2.visible = false
	# Move heal to compact row
	if heal_label.get_parent() == stats_row_2:
		stats_row_2.remove_child(heal_label)
		stats_row_1.add_child(heal_label)
	call_deferred("_refresh_layout")


func _get_viewport_size() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		return viewport.get_visible_rect().size
	return Vector2(1600.0, 900.0)


func _get_hud_scale() -> float:
	return UiTextureUtils.get_viewport_scale(_get_viewport_size(), Vector2(1600.0, 900.0), 0.8, 1.15)


func _on_viewport_resized() -> void:
	call_deferred("_refresh_layout")


func _refresh_layout() -> void:
	_apply_ux_style()
	_layout_hud()
	_layout_notification_layer()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_P:
			perk_tree_requested.emit()
			get_viewport().set_input_as_handled()


func update_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


func update_xp(current: int, needed: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = current


func update_level(level: int) -> void:
	level_label.text = "LVL %d" % level


func update_kills(kills: int) -> void:
	kill_label.text = "☠ %d" % kills


func update_perk_charges(bomb_charges: int, heal_charges: int) -> void:
	bomb_label.text = "💣 %d" % bomb_charges
	heal_label.text = "💚 %d" % heal_charges


func show_notification(message: String, duration: float = 1.8) -> void:
	if message.is_empty():
		return
	_ensure_notification_container()
	if _notification_container == null:
		return

	var panel: PanelContainer = PanelContainer.new()
	UiTextureUtils.apply_nearest_filter(panel)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.08, 0.12, 0.92)
	panel_style.border_color = Color(0.35, 0.62, 0.92, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", panel_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var label: Label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.9))
	label.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	margin.add_child(label)

	_notification_container.add_child(panel)
	while _notification_container.get_child_count() > 4:
		var first_child: Node = _notification_container.get_child(0)
		first_child.queue_free()

	_expire_notification(panel, duration)


func _expire_notification(node: CanvasItem, duration: float) -> void:
	await get_tree().create_timer(maxf(duration, 0.1), true).timeout
	if not is_instance_valid(node):
		return
	var tween: Tween = create_tween()
	tween.tween_property(node, "modulate:a", 0.0, 0.2)
	await tween.finished
	if is_instance_valid(node):
		node.queue_free()


func _ensure_notification_container() -> void:
	if _notification_container != null and is_instance_valid(_notification_container):
		_layout_notification_layer()
		return
	_notification_layer = MarginContainer.new()
	_notification_layer.name = "NotificationLayer"
	_notification_layer.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_notification_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_notification_layer)

	_notification_container = VBoxContainer.new()
	_notification_container.name = "NotificationContainer"
	_notification_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_notification_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_layer.add_child(_notification_container)
	_layout_notification_layer()


func _layout_notification_layer() -> void:
	if _notification_layer == null or not is_instance_valid(_notification_layer):
		_notification_layer = get_node_or_null("NotificationLayer") as MarginContainer
	if _notification_layer == null:
		return
	var viewport_size: Vector2 = _get_viewport_size()
	var hud_scale: float = _get_hud_scale()
	var outer_margin: float = UiTextureUtils.scale_dimension(24.0, hud_scale, 2, 16.0)
	var horizontal_margin: float = clampf(viewport_size.x * 0.22, 220.0, 420.0)
	_notification_layer.offset_left = 0.0
	_notification_layer.offset_top = outer_margin
	_notification_layer.offset_right = 0.0
	_notification_layer.offset_bottom = 0.0
	_notification_layer.add_theme_constant_override("margin_left", int(round(horizontal_margin)))
	_notification_layer.add_theme_constant_override("margin_right", int(round(horizontal_margin)))
	if _notification_container != null and is_instance_valid(_notification_container):
		_notification_container.add_theme_constant_override("separation", int(UiTextureUtils.scale_dimension(6.0, hud_scale, 1, 4.0)))


func show_level_up(options: Array[Dictionary], title: String = "Level Up! Bir yükseltme seç") -> void:
	if options.size() < 3:
		return
	level_up_title.text = title
	var level_up_icon: Texture2D = _load_icon("res://assets/ui/icons/icon_level_up.png")
	if level_up_icon != null:
		level_up_title.text = "  %s  " % title
	option_ids = [
		str(options[0].get("id", "")),
		str(options[1].get("id", "")),
		str(options[2].get("id", ""))
	]
	option_button_a.text = _build_option_text(options[0])
	option_button_b.text = _build_option_text(options[1])
	option_button_c.text = _build_option_text(options[2])
	_apply_rarity_button_style(option_button_a, str(options[0].get("rarity", "")))
	_apply_rarity_button_style(option_button_b, str(options[1].get("rarity", "")))
	_apply_rarity_button_style(option_button_c, str(options[2].get("rarity", "")))
	_apply_rarity_option_icons(option_button_a, options[0])
	_apply_rarity_option_icons(option_button_b, options[1])
	_apply_rarity_option_icons(option_button_c, options[2])
	active_weapons_panel.visible = false
	top_right_container.visible = false
	modal_backdrop.visible = true
	level_up_panel.visible = true


func hide_level_up() -> void:
	option_ids.clear()
	active_weapons_panel.visible = true
	top_right_container.visible = true
	modal_backdrop.visible = false
	level_up_panel.visible = false


func show_game_over(stats: Dictionary = {}) -> void:
	var hud_scale: float = _get_hud_scale()
	game_over_kills_label.text = "⚔ Kills: %d" % int(stats.get("kills", 0))
	game_over_level_label.text = "★ Level: %d" % int(stats.get("level", 1))
	game_over_weapon_label.text = "◆ Weapon: %s" % str(stats.get("weapon", "—"))
	active_weapons_panel.visible = false
	top_right_container.visible = false
	controls_panel.visible = false
	modal_backdrop.visible = true
	game_over_panel.visible = true
	_style_game_over_panel(hud_scale)


func hide_game_over() -> void:
	game_over_panel.visible = false
	modal_backdrop.visible = false
	active_weapons_panel.visible = true
	top_right_container.visible = true


func _on_game_over_restart() -> void:
	hide_game_over()
	game_over_restart_requested.emit()


func _on_game_over_menu() -> void:
	hide_game_over()
	game_over_menu_requested.emit()


func _style_game_over_panel(hud_scale: float) -> void:
	_style_panel(game_over_panel, Color(0.03, 0.02, 0.05, 0.97), Color(0.65, 0.12, 0.18, 0.85))
	game_over_title.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(42.0, hud_scale, 1, 32.0)))
	game_over_title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.25))
	game_over_title.add_theme_constant_override("outline_size", 3)
	game_over_title.add_theme_color_override("font_outline_color", Color(0.12, 0.02, 0.04, 0.95))
	for stat_lbl in [game_over_kills_label, game_over_level_label, game_over_weapon_label]:
		stat_lbl.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(18.0, hud_scale, 1, 15.0)))
		stat_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
		stat_lbl.add_theme_constant_override("outline_size", 1)
		stat_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04, 0.8))
	_style_button(game_over_restart_btn)
	_style_button(game_over_menu_btn)
	game_over_restart_btn.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(18.0, hud_scale, 1, 15.0)))
	game_over_menu_btn.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(15.0, hud_scale, 1, 12.0)))
	var viewport_size: Vector2 = _get_viewport_size()
	var panel_w: float = clampf(viewport_size.x * 0.38, 400.0, 600.0)
	var panel_h: float = clampf(viewport_size.y * 0.48, 320.0, 460.0)
	game_over_panel.offset_left = -panel_w * 0.5
	game_over_panel.offset_right = panel_w * 0.5
	game_over_panel.offset_top = -panel_h * 0.5
	game_over_panel.offset_bottom = panel_h * 0.5


func _emit_option(index: int) -> void:
	if index < 0 or index >= option_ids.size():
		return
	upgrade_selected.emit(option_ids[index])


func _build_option_text(option_data: Dictionary) -> String:
	var rarity: String = str(option_data.get("rarity", ""))
	var category: String = str(option_data.get("category", ""))
	var rarity_prefix: String = ""
	if not rarity.is_empty():
		rarity_prefix = "[%s] " % rarity.capitalize()
	var cat_suffix: String = ""
	if not category.is_empty():
		cat_suffix = " (%s)" % category.replace("_", " ").capitalize()
	return "%s%s%s\n%s" % [
		rarity_prefix,
		str(option_data.get("name", "Upgrade")),
		cat_suffix,
		str(option_data.get("description", ""))
	]


func _on_menu_button_pressed() -> void:
	confirm_menu_panel.visible = true
	modal_backdrop.visible = true
	menu_controls_panel.visible = false
	controls_panel.visible = false
	active_weapons_panel.visible = false
	top_right_container.visible = false
	get_tree().paused = true


func _on_confirm_menu_yes() -> void:
	confirm_menu_panel.visible = false
	modal_backdrop.visible = false
	menu_controls_panel.visible = false
	controls_panel.visible = false
	active_weapons_panel.visible = true
	top_right_container.visible = true
	menu_requested.emit()


func _on_confirm_menu_no() -> void:
	confirm_menu_panel.visible = false
	modal_backdrop.visible = false
	menu_controls_panel.visible = false
	controls_panel.visible = false
	active_weapons_panel.visible = true
	top_right_container.visible = true
	get_tree().paused = false


func _on_controls_toggle_button_pressed() -> void:
	menu_controls_panel.visible = not menu_controls_panel.visible


func _on_perk_tree_button_pressed() -> void:
	perk_tree_requested.emit()


func _on_projectile_switch_button_pressed() -> void:
	projectile_switch_requested.emit()


func update_weapon_display(weapon_name: String) -> void:
	weapon_label.text = "Silah: %s" % weapon_name
	var weapon_id: String = weapon_name.to_lower().replace(" ", "_")
	_update_wrapped_control_icon(weapon_label, _get_weapon_icon_path(weapon_id))


func update_projectile_display(projectile_name: String) -> void:
	projectile_label.text = "Mermi Tipi: %s" % projectile_name


func set_projectile_switch_enabled(enabled: bool) -> void:
	projectile_switch_button.disabled = not enabled


func update_targeting_display(mode_name: String) -> void:
	targeting_label.text = "Nişan [Tab]: %s" % mode_name


func update_active_weapons(weapons_data: Array[Dictionary]) -> void:
	active_weapons_panel.visible = not weapons_data.is_empty()
	var hud_scale: float = _get_hud_scale()
	var viewport_size: Vector2 = _get_viewport_size()
	var target_panel_width: float = clampf(viewport_size.x * 0.56, 360.0, 860.0)
	var card_fit_scale: float = clampf(target_panel_width / maxf(float(max(weapons_data.size(), 1)) * 126.0, 1.0), 0.78, 1.0)
	var card_scale: float = minf(hud_scale, card_fit_scale)
	var card_width: float = UiTextureUtils.scale_dimension(108.0, card_scale, 2, 78.0)
	var card_padding_x: int = int(UiTextureUtils.scale_dimension(6.0, card_scale, 1, 4.0))
	var card_padding_y: int = int(UiTextureUtils.scale_dimension(4.0, card_scale, 1, 3.0))
	var inner_spacing: int = int(UiTextureUtils.scale_dimension(3.0, card_scale, 1, 2.0))
	var stack_spacing: int = int(UiTextureUtils.scale_dimension(2.0, card_scale, 1, 1.0))
	var icon_size: float = UiTextureUtils.scale_dimension(float(ConfigService.get_value("visual.hud.weapon_icon_size", 22)), card_scale, 2, 16.0)
	var label_font_size: int = int(UiTextureUtils.scale_dimension(13.0, card_scale, 1, 11.0))
	var cooldown_height: float = UiTextureUtils.scale_dimension(3.0, card_scale, 1, 2.0)
	# Clear existing weapon indicators
	for child in active_weapons_panel.get_children():
		child.queue_free()
	# Add new weapon indicators
	for wdata in weapons_data:
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(card_width, 0)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var card_style: StyleBoxFlat = StyleBoxFlat.new()
		var wcolor: Color = _get_weapon_display_color(str(wdata.get("name", "")))
		var is_ready: bool = wdata.get("ready", true)
		var is_held: bool = wdata.get("is_held", false)
		var cooldown_pct: float = float(wdata.get("cooldown_pct", 0.0))
		card_style.bg_color = Color(wcolor.r * 0.1, wcolor.g * 0.1, wcolor.b * 0.1, 0.9)
		card_style.border_width_left = 1
		card_style.border_width_top = 1
		card_style.border_width_right = 1
		card_style.border_width_bottom = 1
		if is_held:
			card_style.border_width_left = 2
			card_style.border_width_top = 2
			card_style.border_width_right = 2
			card_style.border_width_bottom = 2
			card_style.shadow_color = Color(wcolor.r, wcolor.g, wcolor.b, 0.2)
			card_style.shadow_size = 4
		card_style.border_color = wcolor if is_ready else wcolor.darkened(0.55)
		card_style.corner_radius_top_left = 4
		card_style.corner_radius_top_right = 4
		card_style.corner_radius_bottom_right = 4
		card_style.corner_radius_bottom_left = 4
		card.add_theme_stylebox_override("panel", card_style)

		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", card_padding_x)
		margin.add_theme_constant_override("margin_right", card_padding_x)
		margin.add_theme_constant_override("margin_top", card_padding_y)
		margin.add_theme_constant_override("margin_bottom", max(2, card_padding_y - 1))
		card.add_child(margin)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", stack_spacing)
		margin.add_child(vbox)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", inner_spacing)
		vbox.add_child(hbox)

		# Weapon icon
		var wid: String = str(wdata.get("id", ""))
		var icon_path: String = _get_weapon_icon_path(wid)
		var icon_tex: Texture2D = _load_icon(icon_path)
		if icon_tex != null:
			var icon_rect: TextureRect = TextureRect.new()
			icon_rect.texture = icon_tex
			icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hbox.add_child(icon_rect)

		var lbl: Label = Label.new()
		var wname: String = str(wdata.get("name", ""))
		lbl.text = wname
		lbl.add_theme_font_size_override("font_size", label_font_size)
		lbl.add_theme_constant_override("outline_size", 1)
		lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.04, 0.9))
		if is_held:
			lbl.add_theme_color_override("font_color", wcolor.lightened(0.5))
		elif is_ready:
			lbl.add_theme_color_override("font_color", wcolor.lightened(0.25))
		else:
			lbl.add_theme_color_override("font_color", Color(0.4, 0.42, 0.48))
		hbox.add_child(lbl)

		# Cooldown progress bar (4px tall, only shown for non-held weapons with a cooldown)
		if not is_held:
			var cd_bar: ProgressBar = ProgressBar.new()
			cd_bar.custom_minimum_size = Vector2(0, cooldown_height)
			cd_bar.max_value = 1.0
			cd_bar.value = 1.0 - cooldown_pct
			cd_bar.show_percentage = false
			var cd_bg: StyleBoxFlat = StyleBoxFlat.new()
			cd_bg.bg_color = Color(wcolor.r * 0.1, wcolor.g * 0.1, wcolor.b * 0.1, 0.8)
			cd_bar.add_theme_stylebox_override("background", cd_bg)
			var cd_fill: StyleBoxFlat = StyleBoxFlat.new()
			cd_fill.bg_color = wcolor if is_ready else wcolor.darkened(0.3)
			cd_fill.corner_radius_top_left = 2
			cd_fill.corner_radius_top_right = 2
			cd_fill.corner_radius_bottom_right = 2
			cd_fill.corner_radius_bottom_left = 2
			cd_bar.add_theme_stylebox_override("fill", cd_fill)
			vbox.add_child(cd_bar)

		active_weapons_panel.add_child(card)


func _get_weapon_display_color(weapon_name: String) -> Color:
	# Map weapon names to their config colors
	var color_map: Dictionary = {
		"Plasma Rifle": Color(0.3, 0.8, 1.0),
		"Nano Swarm": Color(0.0, 1.0, 0.5),
		"Tesla Emitter": Color(0.6, 0.8, 1.0),
		"Scatter Cannon": Color(1.0, 0.6, 0.2),
		"Orbital Sentinel": Color(1.0, 0.9, 0.3),
		"Railgun": Color(1.0, 0.2, 0.2),
		"Void Launcher": Color(0.5, 0.0, 0.8),
		"Arc Blaster": Color(0.4, 0.7, 1.0),
		"Phase Disruptor": Color(0.8, 0.3, 1.0),
		"Gravity Pulse": Color(0.2, 0.4, 0.8),
	}
	for key in color_map:
		if weapon_name.to_lower().contains(key.to_lower()):
			return color_map[key]
	return Color(0.5, 0.7, 1.0)


func _apply_rarity_button_style(button: Button, rarity: String) -> void:
	var rarity_color: Color
	match rarity.to_lower():
		"common":
			rarity_color = Color(0.65, 0.68, 0.72)
		"uncommon":
			rarity_color = Color(0.2, 0.85, 0.35)
		"rare":
			rarity_color = Color(0.25, 0.55, 1.0)
		"epic":
			rarity_color = Color(0.72, 0.22, 1.0)
		"legendary":
			rarity_color = Color(1.0, 0.72, 0.1)
		_:
			rarity_color = Color(0.29, 0.43, 0.63)

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(rarity_color.r * 0.12, rarity_color.g * 0.12, rarity_color.b * 0.12, 1.0)
	normal.border_color = rarity_color.darkened(0.2)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_right = 8
	normal.corner_radius_bottom_left = 8
	normal.shadow_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.22)
	normal.shadow_size = 5

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(rarity_color.r * 0.2, rarity_color.g * 0.2, rarity_color.b * 0.2, 1.0)
	hover.border_color = rarity_color
	hover.shadow_size = 9

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(rarity_color.r * 0.08, rarity_color.g * 0.08, rarity_color.b * 0.08, 1.0)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", rarity_color.lightened(0.3))
	button.add_theme_color_override("font_hover_color", rarity_color.lightened(0.5))


func _apply_rarity_option_icons(button: Button, option_data: Dictionary) -> void:
	var category: String = str(option_data.get("category", ""))
	var icon_map: Dictionary = {
		"active_weapon": "res://assets/ui/icons/icon_targeting.png",
		"passive_weapon": "res://assets/ui/icons/icon_targeting.png",
		"defense": "res://assets/ui/icons/icon_shield.png",
		"mobility": "res://assets/ui/icons/icon_dash.png",
		"utility": "res://assets/ui/icons/icon_xp.png",
		"combat": "res://assets/ui/icons/icon_kill.png",
	}
	var icon_path: String = icon_map.get(category, "res://assets/ui/icons/icon_level_up.png")
	var tex: Texture2D = _load_icon(icon_path)
	if tex != null:
		button.icon = tex
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _apply_ux_style() -> void:
	var viewport_size: Vector2 = _get_viewport_size()
	var hud_scale: float = _get_hud_scale()
	var outer_margin: int = int(UiTextureUtils.scale_dimension(16.0, hud_scale, 2, 12.0))
	hud_margin.add_theme_constant_override("margin_left", outer_margin)
	hud_margin.add_theme_constant_override("margin_top", outer_margin)
	hud_margin.add_theme_constant_override("margin_right", outer_margin)
	hud_margin.add_theme_constant_override("margin_bottom", 0)
	hud_vbox.add_theme_constant_override("separation", int(UiTextureUtils.scale_dimension(3.0, hud_scale, 1, 2.0)))
	stats_row_1.add_theme_constant_override("separation", int(UiTextureUtils.scale_dimension(18.0, hud_scale, 2, 12.0)))
	modal_backdrop.color = Color(0.0, 0.0, 0.02, 0.85)

	# Stats background panel — sleek dark with subtle border
	var stats_style: StyleBoxFlat = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.02, 0.03, 0.06, 0.88)
	stats_style.border_color = Color(0.1, 0.16, 0.26, 0.5)
	stats_style.border_width_left = 1
	stats_style.border_width_top = 1
	stats_style.border_width_right = 1
	stats_style.border_width_bottom = 1
	stats_style.corner_radius_top_left = 2
	stats_style.corner_radius_top_right = 2
	stats_style.corner_radius_bottom_right = 6
	stats_style.corner_radius_bottom_left = 2
	stats_style.shadow_color = Color(0.0, 0.02, 0.06, 0.35)
	stats_style.shadow_size = 6
	stats_bg_panel.add_theme_stylebox_override("panel", stats_style)

	UiTextureUtils.apply_nearest_filter(health_bar)
	UiTextureUtils.apply_nearest_filter(xp_bar)
	UiTextureUtils.apply_nearest_filter(controls_panel)
	UiTextureUtils.apply_nearest_filter(level_up_panel)
	UiTextureUtils.apply_nearest_filter(confirm_menu_panel)
	UiTextureUtils.apply_nearest_filter(game_over_panel)

	# Level label — prominent
	level_label.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(22.0, hud_scale, 1, 18.0)))
	level_label.add_theme_color_override("font_color", Color(0.7, 0.88, 1.0))
	level_label.add_theme_constant_override("outline_size", 3)
	level_label.add_theme_color_override("font_outline_color", Color(0.0, 0.04, 0.12, 0.9))

	# Compact stat labels
	var stat_font_size: int = int(UiTextureUtils.scale_dimension(14.0, hud_scale, 1, 12.0))
	for lbl in [kill_label, bomb_label, heal_label]:
		lbl.add_theme_font_size_override("font_size", stat_font_size)
		lbl.add_theme_constant_override("outline_size", 2)
		lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.04, 0.9))
	kill_label.add_theme_color_override("font_color", Color(0.92, 0.7, 0.55))
	bomb_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.35))
	heal_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))

	# Bar sizes — health full, XP thinner
	var health_bar_w: float = ConfigService.get_value("visual.hud.health_bar_width", HUD_BAR_WIDTH)
	var health_bar_h: float = ConfigService.get_value("visual.hud.health_bar_height", HUD_BAR_HEIGHT)
	var xp_bar_w: float = ConfigService.get_value("visual.hud.xp_bar_width", HUD_BAR_WIDTH)
	var xp_bar_h: float = ConfigService.get_value("visual.hud.xp_bar_height", HUD_BAR_HEIGHT)
	health_bar_w *= clampf(viewport_size.x / 1600.0, 0.82, 1.12)
	health_bar_h *= hud_scale * 0.85
	xp_bar_w *= clampf(viewport_size.x / 1600.0, 0.82, 1.12)
	xp_bar_h *= hud_scale * 0.65
	health_bar_w = _snap_bar_width(health_bar_w)
	health_bar_h = _snap_bar_height(health_bar_h)
	xp_bar_w = _snap_bar_width(xp_bar_w)
	xp_bar_h = _snap_bar_height(xp_bar_h)
	health_bar.custom_minimum_size = Vector2(health_bar_w, health_bar_h)
	xp_bar.custom_minimum_size = Vector2(xp_bar_w, xp_bar_h)

	_style_progress_bar(health_bar, Color(0.85, 0.18, 0.22, 1.0))
	_style_progress_bar(xp_bar, Color(0.2, 0.62, 0.92, 1.0))

	_style_panel(controls_panel, Color(0.03, 0.05, 0.1, 0.95), Color(0.15, 0.25, 0.42, 0.7))
	_style_panel(level_up_panel, Color(0.03, 0.05, 0.1, 0.97), Color(0.2, 0.42, 0.78, 0.85))
	_style_panel(confirm_menu_panel, Color(0.03, 0.05, 0.1, 0.97), Color(0.2, 0.42, 0.78, 0.85))
	active_weapons_panel.modulate.a = 0.95
	active_weapons_panel.add_theme_constant_override("separation", int(UiTextureUtils.scale_dimension(6.0, hud_scale, 1, 4.0)))
	controls_margin.add_theme_constant_override("margin_left", int(UiTextureUtils.scale_dimension(14.0, hud_scale, 1, 10.0)))
	controls_margin.add_theme_constant_override("margin_top", int(UiTextureUtils.scale_dimension(10.0, hud_scale, 1, 8.0)))
	controls_margin.add_theme_constant_override("margin_right", int(UiTextureUtils.scale_dimension(14.0, hud_scale, 1, 10.0)))
	controls_margin.add_theme_constant_override("margin_bottom", int(UiTextureUtils.scale_dimension(10.0, hud_scale, 1, 8.0)))
	controls_vbox.add_theme_constant_override("separation", int(UiTextureUtils.scale_dimension(3.0, hud_scale, 1, 2.0)))
	for control_label in controls_panel.find_children("", "Label", true, false):
		if control_label is Label:
			var label_node: Label = control_label as Label
			var font_size: int = int(UiTextureUtils.scale_dimension(14.0, hud_scale, 1, 11.0))
			if label_node.name == "TitleLabel":
				font_size = int(UiTextureUtils.scale_dimension(16.0, hud_scale, 1, 13.0))
			label_node.add_theme_font_size_override("font_size", font_size)

	for button_node in find_children("", "Button", true, false):
		if button_node is Button:
			var btn := button_node as Button
			UiTextureUtils.apply_nearest_filter(btn)
			if btn == perk_tree_button or btn == projectile_switch_button or btn == menu_button:
				_style_utility_button(btn)
			else:
				_style_button(btn)

	# Top button icons (no wrapping, clean)
	perk_tree_button.icon = _load_icon("res://assets/ui/icons/icon_perk_tree.png")
	projectile_switch_button.icon = _load_icon("res://assets/ui/icons/icon_targeting.png")
	menu_button.icon = _load_icon("res://assets/ui/icons/icon_menu.png")
	perk_tree_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	projectile_switch_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

	level_up_title.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(28.0, hud_scale, 1, 22.0)))
	level_up_title.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	level_up_title.add_theme_constant_override("outline_size", 2)
	level_up_title.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.04, 0.9))
	option_button_a.custom_minimum_size.y = UiTextureUtils.scale_dimension(72.0, hud_scale, 2, 60.0)
	option_button_b.custom_minimum_size.y = option_button_a.custom_minimum_size.y
	option_button_c.custom_minimum_size.y = option_button_a.custom_minimum_size.y


func _layout_hud() -> void:
	var viewport_size: Vector2 = _get_viewport_size()
	var hud_scale: float = _get_hud_scale()
	var outer_margin: float = UiTextureUtils.scale_dimension(16.0, hud_scale, 2, 12.0)
	var sep: float = UiTextureUtils.scale_dimension(3.0, hud_scale, 1, 2.0)
	var level_row_h: float = UiTextureUtils.scale_dimension(24.0, hud_scale, 1, 20.0)
	var stat_row_h: float = UiTextureUtils.scale_dimension(16.0, hud_scale, 1, 13.0)
	# Compact: level + health bar + xp bar + one stat row + separators
	var stats_content_h: float = level_row_h + health_bar.custom_minimum_size.y + xp_bar.custom_minimum_size.y + stat_row_h + sep * 4.0
	var stats_height: float = outer_margin * 2.0 + stats_content_h + 8.0
	var stats_width: float = maxf(outer_margin + health_bar.custom_minimum_size.x + outer_margin, UiTextureUtils.scale_dimension(320.0, hud_scale, 4, 280.0))
	stats_bg_panel.offset_left = 0.0
	stats_bg_panel.offset_top = 0.0
	stats_bg_panel.offset_right = stats_width
	stats_bg_panel.offset_bottom = stats_height

	# Top-right utility buttons — compact
	var btn_h: float = UiTextureUtils.scale_dimension(34.0, hud_scale, 2, 30.0)
	perk_tree_button.custom_minimum_size = Vector2(UiTextureUtils.scale_dimension(100.0, hud_scale, 2, 88.0), btn_h)
	projectile_switch_button.custom_minimum_size = Vector2(UiTextureUtils.scale_dimension(120.0, hud_scale, 2, 104.0), btn_h)
	menu_button.custom_minimum_size = Vector2(UiTextureUtils.scale_dimension(80.0, hud_scale, 2, 72.0), btn_h)
	var top_sep: float = UiTextureUtils.scale_dimension(8.0, hud_scale, 2, 6.0)
	top_right_container.add_theme_constant_override("separation", int(top_sep))
	var top_width: float = perk_tree_button.custom_minimum_size.x + projectile_switch_button.custom_minimum_size.x + menu_button.custom_minimum_size.x + top_sep * 2.0
	top_right_container.offset_left = -outer_margin - top_width
	top_right_container.offset_top = outer_margin
	top_right_container.offset_right = -outer_margin
	top_right_container.offset_bottom = outer_margin + btn_h

	# Weapon panel — bottom center
	var weapon_panel_width: float = clampf(viewport_size.x * 0.56, UiTextureUtils.scale_dimension(360.0, hud_scale, 4, 340.0), UiTextureUtils.scale_dimension(820.0, hud_scale, 4, 820.0))
	var weapon_panel_height: float = UiTextureUtils.scale_dimension(68.0, hud_scale, 2, 52.0)
	active_weapons_panel.offset_left = -weapon_panel_width * 0.5
	active_weapons_panel.offset_right = weapon_panel_width * 0.5
	active_weapons_panel.offset_bottom = -outer_margin
	active_weapons_panel.offset_top = -outer_margin - weapon_panel_height

	var controls_width: float = minf(viewport_size.x * 0.26, UiTextureUtils.scale_dimension(340.0, hud_scale, 4, 260.0))
	var controls_height: float = UiTextureUtils.scale_dimension(270.0, hud_scale, 4, 220.0)
	controls_panel.offset_left = -outer_margin - controls_width
	controls_panel.offset_top = -outer_margin - controls_height
	controls_panel.offset_right = -outer_margin
	controls_panel.offset_bottom = -outer_margin

	var level_width: float = clampf(viewport_size.x * 0.50, UiTextureUtils.scale_dimension(560.0, hud_scale, 4, 480.0), UiTextureUtils.scale_dimension(820.0, hud_scale, 4, 820.0))
	var level_height: float = clampf(viewport_size.y * 0.55, UiTextureUtils.scale_dimension(400.0, hud_scale, 4, 380.0), UiTextureUtils.scale_dimension(580.0, hud_scale, 4, 580.0))
	level_up_panel.offset_left = -level_width * 0.5
	level_up_panel.offset_right = level_width * 0.5
	level_up_panel.offset_top = -level_height * 0.5
	level_up_panel.offset_bottom = level_height * 0.5

	var confirm_width: float = clampf(viewport_size.x * 0.32, UiTextureUtils.scale_dimension(400.0, hud_scale, 4, 340.0), UiTextureUtils.scale_dimension(580.0, hud_scale, 4, 580.0))
	var confirm_height: float = clampf(viewport_size.y * 0.28, UiTextureUtils.scale_dimension(230.0, hud_scale, 4, 210.0), UiTextureUtils.scale_dimension(330.0, hud_scale, 4, 330.0))
	confirm_menu_panel.offset_left = -confirm_width * 0.5
	confirm_menu_panel.offset_right = confirm_width * 0.5
	confirm_menu_panel.offset_top = -confirm_height * 0.5
	confirm_menu_panel.offset_bottom = confirm_height * 0.5


func _style_panel(panel: PanelContainer, bg: Color, border: Color) -> void:
	var panel_path: String = "res://assets/ui/panels/panel_secondary_9slice.png"
	if panel == level_up_panel or panel == confirm_menu_panel:
		panel_path = "res://assets/ui/panels/panel_main_9slice.png"
	var textured: StyleBoxTexture = UiTextureUtils.load_stylebox_texture(panel_path, 24, StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT)
	if textured != null:
		panel.add_theme_stylebox_override("panel", textured)
		return

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_color = Color(0.0, 0.0, 0.02, 0.4)
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)


func _style_progress_bar(bar: ProgressBar, fill_color: Color) -> void:
	var background_path: String = "res://assets/ui/bars/bar_health_frame.png"
	var fill_path: String = "res://assets/ui/bars/bar_health_fill.png"
	if bar == xp_bar:
		background_path = "res://assets/ui/bars/bar_xp_frame.png"
		fill_path = "res://assets/ui/bars/bar_xp_fill.png"

	var textured_bg: StyleBoxTexture = UiTextureUtils.load_center_strip_stylebox_texture(background_path, HUD_BAR_STRIP_HEIGHT)
	var textured_fill: StyleBoxTexture = UiTextureUtils.load_center_strip_stylebox_texture(fill_path, HUD_BAR_STRIP_HEIGHT)
	if textured_bg != null and textured_fill != null:
		bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bar.add_theme_stylebox_override("background", textured_bg)
		bar.add_theme_stylebox_override("fill", textured_fill)
		return

	var background_style: StyleBoxFlat = StyleBoxFlat.new()
	background_style.bg_color = Color(0.06, 0.09, 0.13, 0.95)
	background_style.border_color = Color(0.22, 0.3, 0.42, 1.0)
	background_style.border_width_left = 1
	background_style.border_width_top = 1
	background_style.border_width_right = 1
	background_style.border_width_bottom = 1
	background_style.corner_radius_top_left = 6
	background_style.corner_radius_top_right = 6
	background_style.corner_radius_bottom_right = 6
	background_style.corner_radius_bottom_left = 6

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 5
	fill_style.corner_radius_top_right = 5
	fill_style.corner_radius_bottom_right = 5
	fill_style.corner_radius_bottom_left = 5

	bar.add_theme_stylebox_override("background", background_style)
	bar.add_theme_stylebox_override("fill", fill_style)


func _style_button(button: Button) -> void:
	var hud_scale: float = _get_hud_scale()
	var min_button_height: float = ConfigService.get_value("visual.hud.button_min_height", 56)
	min_button_height = UiTextureUtils.scale_dimension(min_button_height, hud_scale, 2, 44.0)
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, min_button_height)
	button.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(17.0, hud_scale, 1, 14.0)))

	var normal_tex: StyleBoxTexture = UiTextureUtils.load_stylebox_texture("res://assets/ui/panels/button_primary_normal.png", 24, StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT)
	var hover_tex: StyleBoxTexture = UiTextureUtils.load_stylebox_texture("res://assets/ui/panels/button_primary_hover.png", 24, StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT)
	var pressed_tex: StyleBoxTexture = UiTextureUtils.load_stylebox_texture("res://assets/ui/panels/button_primary_pressed.png", 24, StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT)
	var disabled_tex: StyleBoxTexture = UiTextureUtils.load_stylebox_texture("res://assets/ui/panels/button_primary_disabled.png", 24, StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT)
	if normal_tex != null and hover_tex != null and pressed_tex != null and disabled_tex != null:
		button.add_theme_stylebox_override("normal", normal_tex)
		button.add_theme_stylebox_override("hover", hover_tex)
		button.add_theme_stylebox_override("pressed", pressed_tex)
		button.add_theme_stylebox_override("disabled", disabled_tex)
		button.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		button.add_theme_color_override("font_pressed_color", Color(0.83, 0.9, 1.0))
		button.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.58))
		return

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.border_color = Color(0.22, 0.36, 0.58, 1.0)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_right = 4
	normal.corner_radius_bottom_left = 4
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.12, 0.18, 0.3, 1.0)
	hover.border_color = Color(0.35, 0.55, 0.85, 1.0)
	hover.shadow_color = Color(0.15, 0.3, 0.6, 0.2)
	hover.shadow_size = 5

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(0.05, 0.08, 0.14, 1.0)
	pressed.border_color = Color(0.28, 0.44, 0.7, 1.0)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.06, 0.06, 0.08, 0.85)
	disabled.border_color = Color(0.15, 0.16, 0.22, 0.7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.83, 0.9, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.58))


func _style_utility_button(button: Button) -> void:
	var hud_scale: float = _get_hud_scale()
	button.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(13.0, hud_scale, 1, 11.0)))
	button.add_theme_constant_override("outline_size", 1)
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.08, 0.14, 0.85)
	normal.border_color = Color(0.18, 0.28, 0.45, 0.7)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_right = 4
	normal.corner_radius_bottom_left = 4
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.1, 0.15, 0.24, 0.92)
	hover.border_color = Color(0.3, 0.48, 0.75, 0.9)
	hover.shadow_color = Color(0.15, 0.3, 0.6, 0.15)
	hover.shadow_size = 4
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(0.04, 0.06, 0.1, 0.9)
	pressed.border_color = Color(0.25, 0.4, 0.65, 0.8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.6, 0.72, 0.88))
	button.add_theme_color_override("font_hover_color", Color(0.82, 0.92, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.55, 0.65, 0.8))


func _snap_bar_width(value: float) -> float:
	return UiTextureUtils.snap_dimension(value, HUD_BAR_TEXTURE_WIDTH)


func _snap_bar_height(value: float) -> float:
	return UiTextureUtils.snap_dimension(value, HUD_BAR_STRIP_HEIGHT)


func _load_icon(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _update_wrapped_control_icon(control: Control, icon_path: String) -> void:
	if control == null:
		return
	var parent: Node = control.get_parent()
	if not (parent is HBoxContainer):
		return
	if not str(parent.name).begins_with("IconWrap_"):
		return
	var tex: Texture2D = _load_icon(icon_path)
	if tex == null:
		return
	for child in parent.get_children():
		if child is TextureRect:
			(child as TextureRect).texture = tex
			return


func _wrap_control_with_icon(control: Control, icon_path: String, icon_size: float, separation: int = 8) -> void:
	if control == null:
		return
	var parent: Node = control.get_parent()
	if parent == null:
		return
	var tex: Texture2D = _load_icon(icon_path)
	if tex == null:
		return
	if parent is HBoxContainer and str(parent.name).begins_with("IconWrap_"):
		var wrapped_parent: HBoxContainer = parent as HBoxContainer
		wrapped_parent.add_theme_constant_override("separation", separation)
		for child in wrapped_parent.get_children():
			if child is TextureRect:
				var icon_rect: TextureRect = child as TextureRect
				icon_rect.texture = tex
				icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
				break
		return
	var idx: int = control.get_index()
	parent.remove_child(control)
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "IconWrap_%s" % control.name
	row.add_theme_constant_override("separation", separation)
	parent.add_child(row)
	parent.move_child(row, idx)
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.texture = tex
	icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon_rect)
	row.add_child(control)


func _apply_bar_icons() -> void:
	var bar_icon_size: float = float(ConfigService.get_value("visual.hud.icon_size", 28)) * _get_hud_scale()
	_wrap_control_with_icon(health_bar, "res://assets/ui/icons/icon_shield.png", bar_icon_size, 10)
	_wrap_control_with_icon(xp_bar, "res://assets/ui/icons/icon_xp.png", bar_icon_size, 10)


func _apply_control_hint_icons() -> void:
	var hint_icon_size: float = float(ConfigService.get_value("visual.hud.label_icon_size", 24)) * _get_hud_scale()
	var hint_map: Dictionary = {
		get_node_or_null("ControlsPanel/MarginContainer/VBoxContainer/DashLabel"): "res://assets/ui/icons/icon_dash.png",
		get_node_or_null("ControlsPanel/MarginContainer/VBoxContainer/BombHintLabel"): "res://assets/ui/icons/icon_bomb.png",
		get_node_or_null("ControlsPanel/MarginContainer/VBoxContainer/HealHintLabel"): "res://assets/ui/icons/icon_heal.png",
		get_node_or_null("ControlsPanel/MarginContainer/VBoxContainer/TargetingHintLabel"): "res://assets/ui/icons/icon_targeting.png",
		get_node_or_null("ControlsPanel/MarginContainer/VBoxContainer/PerkHintLabel"): "res://assets/ui/icons/icon_perk_tree.png",
	}
	for hint in hint_map:
		if hint is Control:
			_wrap_control_with_icon(hint as Control, str(hint_map[hint]), hint_icon_size, 6)


func _apply_top_button_icons() -> void:
	perk_tree_button.icon = _load_icon("res://assets/ui/icons/icon_perk_tree.png")
	projectile_switch_button.icon = _load_icon("res://assets/ui/icons/icon_targeting.png")
	menu_button.icon = _load_icon("res://assets/ui/icons/icon_menu.png")
	perk_tree_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	projectile_switch_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_label_icons()


func _get_weapon_icon_path(weapon_id: String) -> String:
	var id: String = weapon_id.to_lower().replace(" ", "_")
	var alt_map: Dictionary = {
		"scatter_cannon": "scatter_cannon",
	}
	if alt_map.has(id):
		id = alt_map[id]
	return "res://assets/ui/icons/weapon_%s.png" % id


func _apply_label_icons() -> void:
	var label_icon_size: float = float(ConfigService.get_value("visual.hud.label_icon_size", 24)) * _get_hud_scale()
	_wrap_control_with_icon(level_label, "res://assets/ui/icons/icon_player_hero.png", label_icon_size, 4)
	_wrap_control_with_icon(kill_label, "res://assets/ui/icons/icon_kill.png", label_icon_size, 4)
	_wrap_control_with_icon(bomb_label, "res://assets/ui/icons/icon_bomb.png", label_icon_size, 4)
	_wrap_control_with_icon(heal_label, "res://assets/ui/icons/icon_heal.png", label_icon_size, 4)
	_wrap_control_with_icon(weapon_label, "res://assets/ui/icons/weapon_plasma_rifle.png", label_icon_size, 4)
	_wrap_control_with_icon(targeting_label, "res://assets/ui/icons/icon_targeting.png", label_icon_size, 4)
