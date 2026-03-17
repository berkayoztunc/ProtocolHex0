extends CanvasLayer

signal upgrade_selected(upgrade_id: String)
signal menu_requested
signal perk_tree_requested
signal projectile_switch_requested
signal game_over_restart_requested
signal game_over_menu_requested

@onready var stats_bg_panel: PanelContainer = $StatsBGPanel
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var health_fill: Sprite2D = get_node_or_null("MarginContainer/VBoxContainer/HealthBar/HeathFill") as Sprite2D
@onready var xp_bar: ProgressBar = $MarginContainer/VBoxContainer/XPBar
@onready var xp_fill: Sprite2D = get_node_or_null("MarginContainer/VBoxContainer/XPBar/XPfill") as Sprite2D
@onready var level_label: Label = get_node_or_null("MarginContainer/VBoxContainer/LevelLabel") as Label
@onready var kill_label: Label = get_node_or_null("MarginContainer/VBoxContainer/StatsRow1/KillLabel") as Label
@onready var bomb_label: Label = get_node_or_null("MarginContainer/VBoxContainer/StatsRow1/BombLabel") as Label
@onready var heal_label: Label = get_node_or_null("MarginContainer/VBoxContainer/StatsRow2/HealLabel") as Label
@onready var weapon_label: Label = get_node_or_null("MarginContainer/VBoxContainer/WeaponLabel") as Label
@onready var projectile_label: Label = get_node_or_null("MarginContainer/VBoxContainer/ProjectileLabel") as Label
@onready var targeting_label: Label = get_node_or_null("MarginContainer/VBoxContainer/StatsRow2/TargetingLabel") as Label
@onready var modal_backdrop: ColorRect = $ModalBackdrop
@onready var level_up_panel: PanelContainer = $LevelUpPanel
@onready var level_up_title: Label = get_node_or_null("LevelUpPanel/MarginContainer/VBoxContainer/TitleLabel") as Label
@onready var option_button_a: Button = $LevelUpPanel/MarginContainer/VBoxContainer/OptionButtonA
@onready var option_button_b: Button = $LevelUpPanel/MarginContainer/VBoxContainer/OptionButtonB
@onready var option_button_c: Button = $LevelUpPanel/MarginContainer/VBoxContainer/OptionButtonC
@onready var confirm_menu_panel: PanelContainer = $ConfirmMenuPanel
@onready var controls_panel: PanelContainer = $ControlsPanel
@onready var menu_controls_panel: VBoxContainer = $ConfirmMenuPanel/VBox/MenuControlsPanel
@onready var active_weapons_panel: HBoxContainer = $ActiveWeaponsPanel
@onready var projectile_switch_button: Button = get_node_or_null("TopRightContainer/ProjectileSwitchButton") as Button
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
@onready var game_over_title: Label = get_node_or_null("GameOverPanel/VBox/GameOverTitle") as Label
@onready var game_over_kills_label: Label = get_node_or_null("GameOverPanel/VBox/StatsContainer/KillsStatLabel") as Label
@onready var game_over_level_label: Label = get_node_or_null("GameOverPanel/VBox/StatsContainer/LevelStatLabel") as Label
@onready var game_over_weapon_label: Label = get_node_or_null("GameOverPanel/VBox/StatsContainer/WeaponStatLabel") as Label
@onready var game_over_restart_btn: Button = $GameOverPanel/VBox/RestartButton
@onready var game_over_menu_btn: Button = $GameOverPanel/VBox/MenuButton
@onready var stat_panel: HBoxContainer = get_node_or_null("StatPanel") as HBoxContainer
@onready var stat_level_label: Label = get_node_or_null("StatPanel/Lvl/LVLLabel") as Label
@onready var stat_perk_label: Label = get_node_or_null("StatPanel/Perk/PerkLvl") as Label
@onready var stat_bomb_label: Label = get_node_or_null("StatPanel/Bomb/bomblbl") as Label
@onready var stat_kill_label: Label = get_node_or_null("StatPanel/Killsprt/killlbl") as Label
@onready var alert_stripe: Sprite2D = get_node_or_null("StatPanel/alertStripe") as Sprite2D
@onready var alert_label: Label = get_node_or_null("StatPanel/alertStripe/alertLbl") as Label

const HUD_BAR_TEXTURE_WIDTH := 128
const HUD_BAR_STRIP_HEIGHT := 12
const HUD_BAR_SCALE := 3
const HUD_BAR_WIDTH := HUD_BAR_TEXTURE_WIDTH * HUD_BAR_SCALE
const HUD_BAR_HEIGHT := HUD_BAR_STRIP_HEIGHT * HUD_BAR_SCALE
const SkillBarScene: PackedScene = preload("res://scenes/skill_bar.tscn")

var option_ids: Array[String] = []
var _notification_container: VBoxContainer = null
var _notification_layer: MarginContainer = null
var _health_fill_base_region: Rect2 = Rect2()
var _xp_fill_base_region: Rect2 = Rect2()
var _health_fill_left_x: float = 0.0
var _xp_fill_left_x: float = 0.0
var _alert_tween: Tween = null
var _skill_bar: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_ux_style()
	_ensure_skill_bar()
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
	if projectile_switch_button != null:
		projectile_switch_button.pressed.connect(_on_projectile_switch_button_pressed)
	game_over_restart_btn.pressed.connect(_on_game_over_restart)
	game_over_menu_btn.pressed.connect(_on_game_over_menu)
	_hide_builtin_bar_visuals()
	_prepare_game_over_sprite_ui()
	if health_fill != null:
		if health_fill.region_enabled:
			_health_fill_base_region = health_fill.region_rect
		else:
			var h_tex_size: Vector2 = health_fill.texture.get_size() if health_fill.texture != null else Vector2.ZERO
			_health_fill_base_region = Rect2(Vector2.ZERO, h_tex_size)
		_health_fill_left_x = health_fill.position.x - (_health_fill_base_region.size.x * health_fill.scale.x * 0.5)
	if xp_fill != null:
		if xp_fill.region_enabled:
			_xp_fill_base_region = xp_fill.region_rect
		else:
			var x_tex_size: Vector2 = xp_fill.texture.get_size() if xp_fill.texture != null else Vector2.ZERO
			_xp_fill_base_region = Rect2(Vector2.ZERO, x_tex_size)
		_xp_fill_left_x = xp_fill.position.x - (_xp_fill_base_region.size.x * xp_fill.scale.x * 0.5)
	_update_fill_sprites()
	# Compact HUD: show all labels, restore StatsRow2
	if weapon_label != null:
		weapon_label.visible = true
	if projectile_label != null:
		projectile_label.visible = false
	if targeting_label != null:
		targeting_label.visible = true
	stats_row_2.visible = true
	# Ensure heal is in stats_row_2
	if heal_label != null and heal_label.get_parent() == stats_row_1:
		stats_row_1.remove_child(heal_label)
		stats_row_2.add_child(heal_label)
		stats_row_2.move_child(heal_label, 0)
	if alert_stripe != null:
		alert_stripe.visible = false


func update_skill_bar(weapons_data: Array) -> void:
	_ensure_skill_bar()
	if _skill_bar != null and _skill_bar.has_method("update_weapons"):
		_skill_bar.call("update_weapons", weapons_data)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_P:
			perk_tree_requested.emit()
			get_viewport().set_input_as_handled()


func update_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	_update_health_fill()


func update_xp(current: int, needed: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = current
	_update_xp_fill()


func _update_fill_sprites() -> void:
	_update_health_fill()
	_update_xp_fill()


func _update_health_fill() -> void:
	if health_fill == null:
		return
	var max_value: float = maxf(health_bar.max_value, 0.0001)
	var ratio: float = clampf(health_bar.value / max_value, 0.0, 1.0)
	var region: Rect2 = _health_fill_base_region
	region.size.x = _health_fill_base_region.size.x * ratio
	health_fill.region_enabled = true
	health_fill.region_rect = region
	var draw_width: float = region.size.x * health_fill.scale.x
	health_fill.position.x = _health_fill_left_x + draw_width * 0.5


func _update_xp_fill() -> void:
	if xp_fill == null:
		return
	var max_value: float = maxf(xp_bar.max_value, 0.0001)
	var ratio: float = clampf(xp_bar.value / max_value, 0.0, 1.0)
	var region: Rect2 = _xp_fill_base_region
	region.size.x = _xp_fill_base_region.size.x * ratio
	xp_fill.region_enabled = true
	xp_fill.region_rect = region
	var draw_width: float = region.size.x * xp_fill.scale.x
	xp_fill.position.x = _xp_fill_left_x + draw_width * 0.5


func _hide_builtin_bar_visuals() -> void:
	var empty_fill: StyleBoxEmpty = StyleBoxEmpty.new()
	var empty_bg: StyleBoxEmpty = StyleBoxEmpty.new()
	health_bar.add_theme_stylebox_override("fill", empty_fill)
	health_bar.add_theme_stylebox_override("background", empty_bg)
	xp_bar.add_theme_stylebox_override("fill", empty_fill.duplicate())
	xp_bar.add_theme_stylebox_override("background", empty_bg.duplicate())


func _prepare_game_over_sprite_ui() -> void:
	if game_over_panel != null:
		game_over_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if game_over_restart_btn != null:
		game_over_restart_btn.flat = true
	if game_over_menu_btn != null:
		game_over_menu_btn.flat = true


func update_level(level: int) -> void:
	if level_label != null:
		level_label.text = "LVL %d" % level
	if stat_level_label != null:
		stat_level_label.text = str(level)


func update_kills(kills: int) -> void:
	if kill_label != null:
		kill_label.text = "☠ %d" % kills
	if stat_kill_label != null:
		stat_kill_label.text = str(kills)


func update_perk_charges(bomb_charges: int, heal_charges: int) -> void:
	if bomb_label != null:
		bomb_label.text = "💣 %d" % bomb_charges
	if heal_label != null:
		heal_label.text = "💚 %d" % heal_charges
	if stat_bomb_label != null:
		stat_bomb_label.text = str(bomb_charges)


func update_perk_points(points: int) -> void:
	if stat_perk_label != null:
		stat_perk_label.text = str(points)


func show_notification(message: String, duration: float = 1.8) -> void:
	if message.is_empty():
		return
	if alert_stripe != null and alert_label != null:
		if _alert_tween != null and _alert_tween.is_valid():
			_alert_tween.kill()
		alert_label.text = message
		alert_stripe.visible = true
		alert_stripe.modulate.a = 1.0
		_expire_alert(duration)
		return

	_ensure_notification_container()
	if _notification_container == null:
		return

	var panel: PanelContainer = PanelContainer.new()

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var label: Label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin.add_child(label)

	_notification_container.add_child(panel)
	while _notification_container.get_child_count() > 4:
		var first_child: Node = _notification_container.get_child(0)
		first_child.queue_free()

	_expire_notification(panel, duration)


func _expire_alert(duration: float) -> void:
	await get_tree().create_timer(maxf(duration, 0.1), true).timeout
	if alert_stripe == null or not is_instance_valid(alert_stripe):
		return
	_alert_tween = create_tween()
	_alert_tween.tween_property(alert_stripe, "modulate:a", 0.0, 0.2)
	await _alert_tween.finished
	if alert_stripe != null and is_instance_valid(alert_stripe):
		alert_stripe.visible = false
		alert_stripe.modulate.a = 1.0


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
	_notification_layer.offset_left = 0.0
	_notification_layer.offset_top = 24.0
	_notification_layer.offset_right = 0.0
	_notification_layer.offset_bottom = 0.0
	_notification_layer.add_theme_constant_override("margin_left", 300)
	_notification_layer.add_theme_constant_override("margin_right", 300)
	if _notification_container != null and is_instance_valid(_notification_container):
		_notification_container.add_theme_constant_override("separation", 6)


func show_level_up(options: Array[Dictionary], title: String = "Level Up! Bir yükseltme seç") -> void:
	if options.size() < 3:
		return
	if level_up_title != null:
		level_up_title.text = title
	var level_up_icon: Texture2D = _load_icon("res://assets/ui/icons/icon_level_up.png")
	if level_up_icon != null and level_up_title != null:
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
	if game_over_kills_label != null:
		game_over_kills_label.text = "⚔ Kills: %d" % int(stats.get("kills", 0))
	if game_over_level_label != null:
		game_over_level_label.text = "★ Level: %d" % int(stats.get("level", 1))
	if game_over_weapon_label != null:
		game_over_weapon_label.text = "◆ Weapon: %s" % str(stats.get("weapon", "—"))
	active_weapons_panel.visible = false
	top_right_container.visible = false
	controls_panel.visible = false
	modal_backdrop.visible = true
	game_over_panel.visible = true
	_style_game_over_panel()


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


func _style_game_over_panel() -> void:
	pass


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
	if weapon_label != null:
		weapon_label.text = "Silah: %s" % weapon_name
	var weapon_id: String = weapon_name.to_lower().replace(" ", "_")
	if weapon_label != null:
		_update_wrapped_control_icon(weapon_label, _get_weapon_icon_path(weapon_id))


func update_projectile_display(projectile_name: String) -> void:
	if projectile_label != null:
		projectile_label.text = "Mermi Tipi: %s" % projectile_name


func set_projectile_switch_enabled(enabled: bool) -> void:
	if projectile_switch_button != null:
		projectile_switch_button.disabled = not enabled


func update_targeting_display(mode_name: String) -> void:
	if targeting_label != null:
		targeting_label.text = "Nişan [Tab]: %s" % mode_name


func update_active_weapons(weapons_data: Array[Dictionary]) -> void:
	update_skill_bar(weapons_data)
	active_weapons_panel.visible = not weapons_data.is_empty()
	var card_width: float = 108.0
	var card_padding_x: int = 6
	var card_padding_y: int = 4
	var stack_spacing: int = 2
	var icon_size: float = float(ConfigService.get_value("visual.hud.weapon_icon_size", 22))
	var cooldown_height: float = 3.0
	# Clear existing weapon indicators
	for child in active_weapons_panel.get_children():
		child.queue_free()
	# Add new weapon indicators
	for wdata in weapons_data:
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(card_width, 0)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var is_ready: bool = wdata.get("ready", true)
		var is_held: bool = wdata.get("is_held", false)
		var cooldown_pct: float = float(wdata.get("cooldown_pct", 0.0))

		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", card_padding_x)
		margin.add_theme_constant_override("margin_right", card_padding_x)
		margin.add_theme_constant_override("margin_top", card_padding_y)
		margin.add_theme_constant_override("margin_bottom", max(2, card_padding_y - 1))
		card.add_child(margin)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", stack_spacing)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(vbox)

		# Weapon icon — scaled to fill the card, centered
		var wid: String = str(wdata.get("id", ""))
		var icon_path: String = _get_weapon_icon_path(wid)
		var icon_tex: Texture2D = _load_icon(icon_path)
		if icon_tex != null:
			var icon_rect: TextureRect = TextureRect.new()
			icon_rect.texture = icon_tex
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var card_icon_size: float = maxf(card_width * 0.45, icon_size)
			icon_rect.custom_minimum_size = Vector2(card_icon_size, card_icon_size)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			vbox.add_child(icon_rect)

		# Weapon name label
		var lbl: Label = Label.new()
		var wname: String = str(wdata.get("name", ""))
		lbl.text = wname
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)

		# Cooldown progress bar
		if not is_held:
			var cd_bar: ProgressBar = ProgressBar.new()
			cd_bar.custom_minimum_size = Vector2(0, cooldown_height)
			cd_bar.max_value = 1.0
			cd_bar.value = 1.0 - cooldown_pct
			cd_bar.show_percentage = false
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
	pass


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
	pass


func _layout_hud() -> void:
	pass


func _style_panel(panel: PanelContainer, bg: Color, border: Color) -> void:
	pass


func _style_progress_bar(bar: ProgressBar, fill_color: Color, fill_path: String = "res://assets/ui/bars/bar_fill_orange.png") -> void:
	pass


func _style_button(button: Button) -> void:
	pass


func _style_utility_button(button: Button) -> void:
	pass


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
	var bar_icon_size: float = float(ConfigService.get_value("visual.hud.icon_size", 28))
	_wrap_control_with_icon(health_bar, "res://assets/ui/icons/icon_shield.png", bar_icon_size, 10)
	_wrap_control_with_icon(xp_bar, "res://assets/ui/icons/icon_xp.png", bar_icon_size, 10)


func _apply_control_hint_icons() -> void:
	var hint_icon_size: float = float(ConfigService.get_value("visual.hud.label_icon_size", 24))
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
	if projectile_switch_button != null:
		projectile_switch_button.icon = _load_icon("res://assets/ui/icons/icon_targeting.png")
	menu_button.icon = _load_icon("res://assets/ui/icons/icon_menu.png")
	perk_tree_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if projectile_switch_button != null:
		projectile_switch_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_label_icons()


func _ensure_skill_bar() -> void:
	if _skill_bar != null and is_instance_valid(_skill_bar):
		return
	if SkillBarScene == null:
		return
	var bar_instance: Node = SkillBarScene.instantiate()
	if not (bar_instance is Control):
		return
	_skill_bar = bar_instance as Control
	_skill_bar.name = "SkillBar"
	add_child(_skill_bar)
	move_child(_skill_bar, get_child_count() - 1)
	if _skill_bar.has_method("update_weapons"):
		_skill_bar.call("update_weapons", [])


func _get_weapon_icon_path(weapon_id: String) -> String:
	var id: String = weapon_id.to_lower().replace(" ", "_")
	var alt_map: Dictionary = {
		"scatter_cannon": "scatter_cannon",
	}
	if alt_map.has(id):
		id = alt_map[id]
	return "res://assets/ui/icons/weapon_%s.png" % id


func _apply_label_icons() -> void:
	var label_icon_size: float = float(ConfigService.get_value("visual.hud.label_icon_size", 24))
	if level_label != null:
		_wrap_control_with_icon(level_label, "res://assets/ui/icons/icon_player_hero.png", label_icon_size, 4)
	if kill_label != null:
		_wrap_control_with_icon(kill_label, "res://assets/ui/icons/icon_kill.png", label_icon_size, 4)
	if bomb_label != null:
		_wrap_control_with_icon(bomb_label, "res://assets/ui/icons/icon_bomb.png", label_icon_size, 4)
	if heal_label != null:
		_wrap_control_with_icon(heal_label, "res://assets/ui/icons/icon_heal.png", label_icon_size, 4)
	if weapon_label != null:
		_wrap_control_with_icon(weapon_label, "res://assets/ui/icons/weapon_plasma_rifle.png", label_icon_size, 4)
	if targeting_label != null:
		_wrap_control_with_icon(targeting_label, "res://assets/ui/icons/icon_targeting.png", label_icon_size, 4)
