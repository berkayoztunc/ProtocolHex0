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
@onready var menu_controls_panel: VBoxContainer = $ConfirmMenuPanel/MarginContainer/VBox/MenuControlsPanel
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
@onready var game_over_time_label: Label = get_node_or_null("GameOverPanel/VBox/StatsContainer/TimeStatLabel") as Label
@onready var game_over_restart_btn: Button = $GameOverPanel/VBox/RestartButton
@onready var game_over_menu_btn: Button = $GameOverPanel/VBox/MenuButton
@onready var stat_panel: HBoxContainer = get_node_or_null("StatPanel") as HBoxContainer
@onready var stat_level_label: Label = get_node_or_null("StatPanel/Lvl/LVLLabel") as Label
@onready var stat_perk_label: Label = get_node_or_null("StatPanel/Perk/PerkLvl") as Label
@onready var stat_kill_label: Label = get_node_or_null("StatPanel/Killsprt/killlbl") as Label
@onready var alert_stripe: Sprite2D = get_node_or_null("StatPanel/alertStripe") as Sprite2D
@onready var alert_label: Label = get_node_or_null("StatPanel/alertStripe/alertLbl") as Label

const HUD_BAR_TEXTURE_WIDTH := 128
const HUD_BAR_STRIP_HEIGHT := 12
const HUD_BAR_SCALE := 3
const HUD_BAR_WIDTH := HUD_BAR_TEXTURE_WIDTH * HUD_BAR_SCALE
const HUD_BAR_HEIGHT := HUD_BAR_STRIP_HEIGHT * HUD_BAR_SCALE
const SkillBarScene: PackedScene = preload("res://scenes/skill_bar.tscn")
const MobileJoystickScene: PackedScene = preload("res://scenes/mobile_joystick.tscn")

var _mobile_joystick: Control = null
var option_ids: Array[String] = []
var _notification_container: VBoxContainer = null
var _notification_layer: MarginContainer = null
var _health_fill_base_region: Rect2 = Rect2()
var _xp_fill_base_region: Rect2 = Rect2()
var _health_fill_left_x: float = 0.0
var _xp_fill_left_x: float = 0.0
var _alert_tween: Tween = null
var _skill_bar: Control = null
var _health_ghost: Sprite2D = null
var _xp_ghost: Sprite2D = null
var _health_ratio: float = 1.0
var _xp_ratio: float = 0.0
var _health_ghost_tween: Tween = null
var _xp_fill_tween: Tween = null

var _task_btn: Button = null
var _bag_btn: Button = null

# --- Zone/Inventory/Recall/LevelComplete UI ---
var _inventory_panel: PanelContainer = null
var _inv_labels: Dictionary = {}          # {"scrap": Label, "battery": Label, "nanochips": Label}
var _task_panel: PanelContainer = null
var _task_item_labels: Dictionary = {}    # {task_id: Label}
var _level_complete_panel: PanelContainer = null
var _recall_status_label: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_ux_style()
	_ensure_skill_bar()
	_set_weapon_ui_visible(true)
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
	game_over_restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	modal_backdrop.process_mode = Node.PROCESS_MODE_ALWAYS
	perk_tree_button.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
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
	_setup_bar_ghosts()
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
	_ensure_inventory_panel()
	_setup_modal_buttons()
	if MobileDetector.is_mobile():
		_setup_mobile_controls()


func _setup_mobile_controls() -> void:
	_mobile_joystick = MobileJoystickScene.instantiate()
	_mobile_joystick.z_index = 10
	add_child(_mobile_joystick)


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
	var new_ratio: float = clampf(health_bar.value / max_value, 0.0, 1.0)
	_apply_ratio_to_fill_sprite(health_fill, _health_fill_base_region, _health_fill_left_x, new_ratio)
	if _health_ghost != null:
		if new_ratio < _health_ratio - 0.001:
			# Damage taken – red ghost holds old width, then drains
			if _health_ghost_tween != null and _health_ghost_tween.is_valid():
				_health_ghost_tween.kill()
			_apply_ratio_to_fill_sprite(_health_ghost, _health_fill_base_region, _health_fill_left_x, _health_ratio)
			_health_ghost.visible = true
			var ghost_start: float = _health_ratio
			_health_ghost_tween = create_tween()
			_health_ghost_tween.tween_interval(0.3)
			_health_ghost_tween.tween_method(
				func(r: float) -> void: _apply_ratio_to_fill_sprite(_health_ghost, _health_fill_base_region, _health_fill_left_x, r),
				ghost_start, new_ratio, 0.45
			)
			_health_ghost_tween.tween_callback(func() -> void: _health_ghost.visible = false)
		else:
			# Heal or same – snap ghost away
			if _health_ghost_tween != null and _health_ghost_tween.is_valid():
				_health_ghost_tween.kill()
			_health_ghost.visible = false
	_health_ratio = new_ratio


func _update_xp_fill() -> void:
	if xp_fill == null:
		return
	var max_value: float = maxf(xp_bar.max_value, 0.0001)
	var new_ratio: float = clampf(xp_bar.value / max_value, 0.0, 1.0)
	if _xp_ghost != null and new_ratio > _xp_ratio + 0.001:
		# XP gained – green ghost jumps ahead, fill catches up
		if _xp_fill_tween != null and _xp_fill_tween.is_valid():
			_xp_fill_tween.kill()
		_apply_ratio_to_fill_sprite(_xp_ghost, _xp_fill_base_region, _xp_fill_left_x, new_ratio)
		_xp_ghost.visible = true
		var fill_start: float = _xp_ratio
		_xp_fill_tween = create_tween()
		_xp_fill_tween.tween_method(
			func(r: float) -> void: _apply_ratio_to_fill_sprite(xp_fill, _xp_fill_base_region, _xp_fill_left_x, r),
			fill_start, new_ratio, 0.35
		)
		_xp_fill_tween.tween_callback(func() -> void: _xp_ghost.visible = false)
	else:
		# XP reset (level-up) or same – snap both
		if _xp_fill_tween != null and _xp_fill_tween.is_valid():
			_xp_fill_tween.kill()
		_apply_ratio_to_fill_sprite(xp_fill, _xp_fill_base_region, _xp_fill_left_x, new_ratio)
		if _xp_ghost != null:
			_xp_ghost.visible = false
	_xp_ratio = new_ratio


func _apply_ratio_to_fill_sprite(sprite: Sprite2D, base_region: Rect2, left_x: float, ratio: float) -> void:
	var region: Rect2 = base_region
	region.size.x = base_region.size.x * ratio
	sprite.region_enabled = true
	sprite.region_rect = region
	var draw_width: float = region.size.x * sprite.scale.x
	sprite.position.x = left_x + draw_width * 0.5


func _make_ghost_sprite(source: Sprite2D) -> Sprite2D:
	var ghost: Sprite2D = Sprite2D.new()
	ghost.texture = source.texture
	ghost.scale = source.scale
	ghost.position = source.position
	ghost.region_enabled = source.region_enabled
	ghost.region_rect = source.region_rect
	ghost.visible = false
	return ghost


func _setup_bar_ghosts() -> void:
	if health_fill != null:
		_health_ghost = _make_ghost_sprite(health_fill)
		_health_ghost.modulate = Color(1.0, 0.22, 0.22, 0.78)
		var hfill_idx: int = health_fill.get_index()
		health_fill.get_parent().add_child(_health_ghost)
		health_fill.get_parent().move_child(_health_ghost, hfill_idx)
	if xp_fill != null:
		_xp_ghost = _make_ghost_sprite(xp_fill)
		_xp_ghost.modulate = Color(0.2, 1.0, 0.35, 0.72)
		var xfill_idx: int = xp_fill.get_index()
		xp_fill.get_parent().add_child(_xp_ghost)
		xp_fill.get_parent().move_child(_xp_ghost, xfill_idx)


func _hide_builtin_bar_visuals() -> void:
	var empty_fill: StyleBoxEmpty = StyleBoxEmpty.new()
	var empty_bg: StyleBoxEmpty = StyleBoxEmpty.new()
	health_bar.add_theme_stylebox_override("fill", empty_fill)
	health_bar.add_theme_stylebox_override("background", empty_bg)
	xp_bar.add_theme_stylebox_override("fill", empty_fill.duplicate())
	xp_bar.add_theme_stylebox_override("background", empty_bg.duplicate())


func _prepare_game_over_sprite_ui() -> void:
	pass


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


func show_level_up(options: Array[Dictionary], title: String = "Level Up! Choose an upgrade") -> void:
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
	_set_weapon_ui_visible(false)
	top_right_container.visible = false
	modal_backdrop.visible = true
	level_up_panel.visible = true


func hide_level_up() -> void:
	option_ids.clear()
	_set_weapon_ui_visible(true)
	top_right_container.visible = true
	modal_backdrop.visible = false
	level_up_panel.visible = false


func show_game_over(stats: Dictionary = {}) -> void:
	if game_over_kills_label != null:
		game_over_kills_label.text = "⚔  Kills: %d" % int(stats.get("kills", 0))
	if game_over_level_label != null:
		game_over_level_label.text = "★  Level: %d" % int(stats.get("level", 1))
	if game_over_weapon_label != null:
		game_over_weapon_label.text = "◆  Weapon: %s" % str(stats.get("weapon", "—"))
	if game_over_time_label != null:
		var total_secs: int = int(stats.get("time", 0))
		game_over_time_label.text = "⏱  Time: %d:%02d" % [total_secs / 60, total_secs % 60]
	_set_weapon_ui_visible(false)
	top_right_container.visible = false
	controls_panel.visible = false
	modal_backdrop.color = Color(0.0, 0.0, 0.05, 0.78)
	modal_backdrop.visible = true
	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS  # clickable while paused
	game_over_panel.visible = true
	# Ensure the backdrop and panel sit above any dynamically added notification nodes
	move_child(modal_backdrop, get_child_count() - 1)
	move_child(game_over_panel, get_child_count() - 1)
	_style_game_over_panel()


func hide_game_over() -> void:
	game_over_panel.visible = false
	modal_backdrop.color = Color(1, 1, 1, 0.0627451)
	modal_backdrop.visible = false
	_set_weapon_ui_visible(true)
	top_right_container.visible = true


func _on_game_over_restart() -> void:
	hide_game_over()
	game_over_restart_requested.emit()


func _on_game_over_menu() -> void:
	hide_game_over()
	game_over_menu_requested.emit()


func _style_game_over_panel() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.04, 0.10, 0.97)
	panel_style.border_color = Color(0.72, 0.12, 0.18, 0.90)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 40.0
	panel_style.content_margin_right = 40.0
	panel_style.content_margin_top = 30.0
	panel_style.content_margin_bottom = 30.0
	game_over_panel.add_theme_stylebox_override("panel", panel_style)
	if game_over_title != null:
		game_over_title.add_theme_font_size_override("font_size", 44)
		game_over_title.add_theme_color_override("font_color", Color(1.0, 0.22, 0.28, 1.0))
		game_over_title.add_theme_constant_override("outline_size", 3)
		game_over_title.add_theme_color_override("font_outline_color", Color(0.12, 0.02, 0.04, 0.95))
	for stat_lbl: Label in [game_over_kills_label, game_over_level_label, game_over_weapon_label, game_over_time_label]:
		if stat_lbl != null:
			stat_lbl.add_theme_font_size_override("font_size", 20)
			stat_lbl.add_theme_color_override("font_color", Color(0.78, 0.84, 0.94))
			stat_lbl.add_theme_constant_override("outline_size", 1)
			stat_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.06, 0.85))
	if game_over_restart_btn != null:
		game_over_restart_btn.flat = false
		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(0.18, 0.08, 0.30, 1.0)
		rs.border_color = Color(0.55, 0.30, 0.85, 0.9)
		rs.set_border_width_all(2)
		rs.corner_radius_top_left = 5
		rs.corner_radius_top_right = 5
		rs.corner_radius_bottom_left = 5
		rs.corner_radius_bottom_right = 5
		rs.content_margin_left = 16.0
		rs.content_margin_right = 16.0
		var rs_h := rs.duplicate() as StyleBoxFlat
		rs_h.bg_color = Color(0.26, 0.12, 0.44, 1.0)
		var rs_p := rs.duplicate() as StyleBoxFlat
		rs_p.bg_color = Color(0.12, 0.05, 0.20, 1.0)
		game_over_restart_btn.add_theme_stylebox_override("normal", rs)
		game_over_restart_btn.add_theme_stylebox_override("hover", rs_h)
		game_over_restart_btn.add_theme_stylebox_override("pressed", rs_p)
		game_over_restart_btn.add_theme_font_size_override("font_size", 22)
		game_over_restart_btn.add_theme_color_override("font_color", Color(0.92, 0.85, 1.0))
	if game_over_menu_btn != null:
		game_over_menu_btn.flat = false
		var ms := StyleBoxFlat.new()
		ms.bg_color = Color(0.08, 0.08, 0.16, 1.0)
		ms.border_color = Color(0.35, 0.38, 0.56, 0.80)
		ms.set_border_width_all(2)
		ms.corner_radius_top_left = 5
		ms.corner_radius_top_right = 5
		ms.corner_radius_bottom_left = 5
		ms.corner_radius_bottom_right = 5
		ms.content_margin_left = 16.0
		ms.content_margin_right = 16.0
		var ms_h := ms.duplicate() as StyleBoxFlat
		ms_h.bg_color = Color(0.14, 0.14, 0.26, 1.0)
		game_over_menu_btn.add_theme_stylebox_override("normal", ms)
		game_over_menu_btn.add_theme_stylebox_override("hover", ms_h)
		game_over_menu_btn.add_theme_font_size_override("font_size", 18)
		game_over_menu_btn.add_theme_color_override("font_color", Color(0.72, 0.78, 0.92))


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
	_set_weapon_ui_visible(false)
	top_right_container.visible = false
	get_tree().paused = true


func _on_confirm_menu_yes() -> void:
	confirm_menu_panel.visible = false
	modal_backdrop.visible = false
	menu_controls_panel.visible = false
	controls_panel.visible = false
	_set_weapon_ui_visible(true)
	top_right_container.visible = true
	menu_requested.emit()


func _on_confirm_menu_no() -> void:
	confirm_menu_panel.visible = false
	modal_backdrop.visible = false
	menu_controls_panel.visible = false
	controls_panel.visible = false
	_set_weapon_ui_visible(true)
	top_right_container.visible = true
	get_tree().paused = false


func _on_controls_toggle_button_pressed() -> void:
	menu_controls_panel.visible = not menu_controls_panel.visible


func _on_perk_tree_button_pressed() -> void:
	perk_tree_requested.emit()


func _setup_modal_buttons() -> void:
	# Task list toggle button
	_task_btn = Button.new()
	_task_btn.text = "Tasks"
	_task_btn.custom_minimum_size = Vector2(102, 38)
	_task_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_style_utility_button(_task_btn)
	_task_btn.pressed.connect(_on_task_button_pressed)
	top_right_container.add_child(_task_btn)
	top_right_container.move_child(_task_btn, 0)
	# Bag / inventory toggle button
	_bag_btn = Button.new()
	_bag_btn.text = "Inventory"
	_bag_btn.custom_minimum_size = Vector2(102, 38)
	_bag_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_style_utility_button(_bag_btn)
	_bag_btn.pressed.connect(_on_bag_button_pressed)
	top_right_container.add_child(_bag_btn)
	top_right_container.move_child(_bag_btn, 1)


func _on_task_button_pressed() -> void:
	if _task_panel != null and is_instance_valid(_task_panel):
		_task_panel.visible = not _task_panel.visible


func _on_bag_button_pressed() -> void:
	if _inventory_panel != null and is_instance_valid(_inventory_panel):
		_inventory_panel.visible = not _inventory_panel.visible


func _on_projectile_switch_button_pressed() -> void:
	projectile_switch_requested.emit()


func update_weapon_display(weapon_name: String) -> void:
	if weapon_label != null:
		weapon_label.text = "Weapon: %s" % weapon_name
	var weapon_id: String = weapon_name.to_lower().replace(" ", "_")
	if weapon_label != null:
		_update_wrapped_control_icon(weapon_label, _get_weapon_icon_path(weapon_id))


func update_projectile_display(projectile_name: String) -> void:
	if projectile_label != null:
		projectile_label.text = "Ammo Type: %s" % projectile_name


func set_projectile_switch_enabled(enabled: bool) -> void:
	if projectile_switch_button != null:
		projectile_switch_button.disabled = not enabled


func update_targeting_display(mode_name: String) -> void:
	if targeting_label != null:
		targeting_label.text = "Targeting [Tab]: %s" % mode_name


func update_active_weapons(weapons_data: Array[Dictionary]) -> void:
	update_skill_bar(weapons_data)
	_set_weapon_ui_visible(not weapons_data.is_empty())


func _set_weapon_ui_visible(visible_value: bool) -> void:
	if _skill_bar != null and is_instance_valid(_skill_bar):
		_skill_bar.visible = visible_value


func _get_weapon_display_color(weapon_name: String) -> Color:
	# Map weapon names to their config colors
	var color_map: Dictionary = {
		"Plasma Rifle": Color(0.3, 0.8, 1.0),
		"Burst Sweep": Color(0.0, 1.0, 0.7),
		"Tesla Emitter": Color(0.6, 0.8, 1.0),
		"Rapid Fire": Color(1.0, 0.7, 0.2),
		"Orbital Sentinel": Color(1.0, 0.9, 0.3),
		"Flame Mode": Color(1.0, 0.3, 0.0),
		"Explosion Mode": Color(1.0, 0.7, 0.0),
		"Railgun": Color(1.0, 0.2, 0.2),
		"Rocket Launcher": Color(1.0, 0.5, 0.1),
		"Arc Blaster": Color(0.4, 0.7, 1.0),
		"Cryogen Field": Color(0.0, 0.8, 1.0),
		"Energy Wave": Color(0.3, 0.6, 1.0),
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
	if heal_label != null:
		_wrap_control_with_icon(heal_label, "res://assets/ui/icons/icon_heal.png", label_icon_size, 4)
	if weapon_label != null:
		_wrap_control_with_icon(weapon_label, "res://assets/ui/icons/weapon_plasma_rifle.png", label_icon_size, 4)
	if targeting_label != null:
		_wrap_control_with_icon(targeting_label, "res://assets/ui/icons/icon_targeting.png", label_icon_size, 4)


# =====================================================================
#  INVENTORY PANEL (Scrap / Battery / Nanochips)
# =====================================================================

func _ensure_inventory_panel() -> void:
	if _inventory_panel != null:
		return
	_inventory_panel = PanelContainer.new()
	_inventory_panel.name = "InventoryPanel"
	# Anchor bottom-left
	_inventory_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_inventory_panel.offset_bottom = -8.0
	_inventory_panel.offset_left = 8.0
	_inventory_panel.offset_top = _inventory_panel.offset_bottom - 80.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.75)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.3, 0.5, 0.6)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	_inventory_panel.add_theme_stylebox_override("panel", style)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	_inventory_panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	# Title
	var title: Label = Label.new()
	title.text = "[ INVENTORY ]"
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", Color(0.6, 0.7, 1.0, 0.8))
	vbox.add_child(title)
	# Resource rows
	const RESOURCE_COLORS: Dictionary = {
		"scrap":     Color(0.75, 0.75, 0.80),
		"battery":   Color(1.0,  0.85, 0.1),
		"nanochips": Color(0.6,  0.4,  1.0)
	}
	const RESOURCE_LABELS: Dictionary = {
		"scrap":     "Scrap",
		"battery":   "Battery",
		"nanochips": "Nanochips"
	}
	for res_key in ["scrap", "battery", "nanochips"]:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)
		var dot: Label = Label.new()
		dot.text = "■"
		dot.add_theme_font_size_override("font_size", 8)
		dot.add_theme_color_override("font_color", RESOURCE_COLORS[res_key] as Color)
		row.add_child(dot)
		var name_lbl: Label = Label.new()
		name_lbl.text = RESOURCE_LABELS[res_key] as String
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.90))
		row.add_child(name_lbl)
		var count_lbl: Label = Label.new()
		count_lbl.text = "0"
		count_lbl.add_theme_font_size_override("font_size", 10)
		count_lbl.add_theme_color_override("font_color", RESOURCE_COLORS[res_key] as Color)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(count_lbl)
		_inv_labels[res_key] = count_lbl
	add_child(_inventory_panel)
	_inventory_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_inventory_panel.visible = false  # Hidden by default — toggle via Inventory button


func update_inventory(scrap: int, battery: int, nanochips: int) -> void:
	if _inv_labels.has("scrap"):
		(_inv_labels["scrap"] as Label).text = str(scrap)
	if _inv_labels.has("battery"):
		(_inv_labels["battery"] as Label).text = str(battery)
	if _inv_labels.has("nanochips"):
		(_inv_labels["nanochips"] as Label).text = str(nanochips)


# =====================================================================
#  TASK LIST PANEL (Zone Objectives)
# =====================================================================

func show_task_list(tasks: Array[Dictionary]) -> void:
	if _task_panel != null:
		_task_panel.queue_free()
		_task_panel = null
	if tasks.is_empty():
		return
	_task_panel = PanelContainer.new()
	_task_panel.name = "TaskPanel"
	_task_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_task_panel.offset_right = -8.0
	_task_panel.offset_top = 8.0
	_task_panel.offset_left = _task_panel.offset_right - 200.0
	_task_panel.offset_bottom = _task_panel.offset_top + 120.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.04, 0.75)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.6, 0.2, 0.6)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	_task_panel.add_theme_stylebox_override("panel", style)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	_task_panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)
	var title: Label = Label.new()
	title.text = "[ TASKS ]"
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 0.8))
	vbox.add_child(title)
	_task_item_labels.clear()
	for task in tasks:
		var t: Dictionary = task as Dictionary
		var task_id: String = str(t.get("id", ""))
		var name_str: String = str(t.get("display_name", task_id))
		var current: int = int(t.get("current", 0))
		var required: int = int(t.get("required", 1))
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)
		var check: Label = Label.new()
		check.text = "○"
		check.add_theme_font_size_override("font_size", 10)
		check.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		row.add_child(check)
		var lbl: Label = Label.new()
		lbl.text = "%s: %d/%d" % [name_str, current, required]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		_task_item_labels[task_id] = {"label": lbl, "check": check}
	add_child(_task_panel)
	_task_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_task_panel.visible = false  # Hidden by default — toggle via Tasks button


func update_task(task: Dictionary) -> void:
	var task_id: String = str(task.get("id", ""))
	if not _task_item_labels.has(task_id):
		return
	var entry: Dictionary = _task_item_labels[task_id] as Dictionary
	var lbl: Label = entry.get("label", null) as Label
	var check: Label = entry.get("check", null) as Label
	if lbl == null:
		return
	var name_str: String = str(task.get("display_name", task_id))
	var current: int = int(task.get("current", 0))
	var required: int = int(task.get("required", 1))
	var done: bool = bool(task.get("done", false))
	lbl.text = "%s: %d/%d" % [name_str, current, required]
	if done:
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		if check != null:
			check.text = "●"
			check.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	else:
		lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
		if check != null:
			check.text = "○"
			check.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))


# =====================================================================
#  LEVEL COMPLETE PANEL
# =====================================================================

func show_level_complete(stats: Dictionary) -> void:
	if _level_complete_panel != null:
		_level_complete_panel.queue_free()
	_level_complete_panel = PanelContainer.new()
	_level_complete_panel.name = "LevelCompletePanel"
	_level_complete_panel.process_mode = Node.PROCESS_MODE_ALWAYS  # works while paused
	_level_complete_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_level_complete_panel.offset_left = -200.0
	_level_complete_panel.offset_right = 200.0
	_level_complete_panel.offset_top = -150.0
	_level_complete_panel.offset_bottom = 150.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.04, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.9, 0.3, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_level_complete_panel.add_theme_stylebox_override("panel", style)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_level_complete_panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	# Title
	var title: Label = Label.new()
	title.text = "LEVEL COMPLETE!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	vbox.add_child(title)
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	# Stats
	var minutes: int = int(stats.get("time", 0)) / 60
	var seconds: int = int(stats.get("time", 0)) % 60
	var stats_text: String = "Kills: %d\nLevel: %d\nTime: %02d:%02d" % [
		int(stats.get("kills", 0)),
		int(stats.get("level", 1)),
		minutes, seconds
	]
	var stats_lbl: Label = Label.new()
	stats_lbl.text = stats_text
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 13)
	stats_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
	vbox.add_child(stats_lbl)
	# Zone items collected
	var items: Dictionary = stats.get("items", {}) as Dictionary
	if not items.is_empty():
		var items_lbl: Label = Label.new()
		var items_parts: Array[String] = []
		for k in items.keys():
			items_parts.append("%s: %d" % [str(k), int(items[k])])
		items_lbl.text = "Collected: " + ", ".join(items_parts)
		items_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_lbl.add_theme_font_size_override("font_size", 11)
		items_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
		vbox.add_child(items_lbl)
	# Vault transfer confirmation
	var vault_added: Dictionary = stats.get("vault_added", {}) as Dictionary
	if not vault_added.is_empty():
		var vault_parts: Array[String] = []
		for k in vault_added.keys():
			if int(vault_added[k]) > 0:
				vault_parts.append("%s: +%d" % [str(k), int(vault_added[k])])
		if not vault_parts.is_empty():
			var vault_lbl: Label = Label.new()
			vault_lbl.text = "✓ Added to vault: " + ", ".join(vault_parts)
			vault_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vault_lbl.add_theme_font_size_override("font_size", 11)
			vault_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
			vbox.add_child(vault_lbl)
	var sep2: HSeparator = HSeparator.new()
	vbox.add_child(sep2)
	# Inventory summary (meta-resource progress)
	var inv_lbl: Label = Label.new()
	inv_lbl.text = "Inventory: %d Scrap, %d Battery, %d Nanochips" % [
		Session.get_inventory_count("scrap"),
		Session.get_inventory_count("battery"),
		Session.get_inventory_count("nanochips")
	]
	inv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_lbl.add_theme_font_size_override("font_size", 11)
	inv_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(inv_lbl)
	var sep3: HSeparator = HSeparator.new()
	vbox.add_child(sep3)
	# Menu button
	var menu_btn: Button = Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.add_theme_font_size_override("font_size", 14)
	menu_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
	)
	vbox.add_child(menu_btn)
	add_child(_level_complete_panel)


# =====================================================================
#  RECALL STATUS INDICATOR
# =====================================================================

func show_recall_cooldown(seconds: float) -> void:
	_ensure_recall_label()
	_recall_status_label.text = "R: %.0fs" % maxf(seconds, 0.0)
	_recall_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
	_recall_status_label.visible = true
	if _skill_bar != null and is_instance_valid(_skill_bar) and _skill_bar.has_method("update_recall_state"):
		_skill_bar.call("update_recall_state", "cooldown", seconds)


func show_recall_ready() -> void:
	_ensure_recall_label()
	_recall_status_label.text = "R: Ready"
	_recall_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	_recall_status_label.visible = true
	if _skill_bar != null and is_instance_valid(_skill_bar) and _skill_bar.has_method("update_recall_state"):
		_skill_bar.call("update_recall_state", "ready")


func _ensure_recall_label() -> void:
	if _recall_status_label != null and is_instance_valid(_recall_status_label):
		return
	_recall_status_label = Label.new()
	_recall_status_label.name = "RecallStatusLabel"
	_recall_status_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_recall_status_label.anchor_top = 1.0
	_recall_status_label.anchor_bottom = 1.0
	_recall_status_label.offset_top = -36.0
	_recall_status_label.offset_bottom = -10.0
	_recall_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recall_status_label.add_theme_font_size_override("font_size", 16)
	_recall_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	_recall_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_recall_status_label.visible = false
	add_child(_recall_status_label)
