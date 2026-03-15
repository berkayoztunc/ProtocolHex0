extends Control

const UiTextureUtils = preload("res://scripts/ui_texture_utils.gd")

@onready var name_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NameInput
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton
@onready var settings_panel: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsPanel
@onready var controls_panel: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ControlsPanel
@onready var master_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsPanel/MasterVolumeSlider
@onready var background: ColorRect = $Background
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Title
@onready var main_vbox: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer
@onready var start_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StartButton
@onready var continue_action_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton
@onready var controls_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ControlsButton
@onready var controls_dash_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ControlsPanel/ControlsDash
@onready var controls_bomb_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ControlsPanel/ControlsBomb
@onready var controls_heal_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ControlsPanel/ControlsHeal
@onready var controls_target_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ControlsPanel/ControlsTarget
@onready var controls_perk_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ControlsPanel/ControlsPerk

var _hero_preview_sprite: AnimatedSprite2D = null
var _hero_preview_node: Node2D = null
var _hero_preview_glow: Sprite2D = null
var _hero_preview_source_side: float = 0.0

func _ready() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_resized):
		viewport.size_changed.connect(_on_viewport_resized)
	name_input.text = Session.player_name
	continue_button.disabled = not Session.has_last_run()
	settings_panel.visible = false
	controls_panel.visible = false
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	_setup_background_texture()
	_apply_ux_style()
	_apply_menu_icons()
	_setup_hero_preview()
	call_deferred("_refresh_layout")


func _get_viewport_size() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		return viewport.get_visible_rect().size
	return Vector2(1600.0, 900.0)


func _get_menu_scale() -> float:
	return UiTextureUtils.get_viewport_scale(_get_viewport_size(), Vector2(1600.0, 900.0), 0.8, 1.12)


func _on_viewport_resized() -> void:
	call_deferred("_refresh_layout")


func _refresh_layout() -> void:
	_apply_ux_style()
	_apply_responsive_layout()


func _setup_background_texture() -> void:
	var bg_path: String = "res://assets/ui/backgrounds/start_menu_bg.png"
	if not ResourceLoader.exists(bg_path):
		return
	var bg_tex: Texture2D = load(bg_path) as Texture2D
	if bg_tex == null:
		return
	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.name = "BackgroundTexture"
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	texture_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.texture = bg_tex
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(texture_rect)
	move_child(texture_rect, 0)


func _on_start_button_pressed() -> void:
	Session.start_new_run(name_input.text)
	MockApiClient.queue_event("run_started", {"player_name": Session.player_name})
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_continue_button_pressed() -> void:
	if not Session.has_last_run():
		return
	Session.start_continue_run()
	MockApiClient.queue_event("run_continue", {"player_name": Session.player_name})
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_settings_button_pressed() -> void:
	settings_panel.visible = not settings_panel.visible


func _on_controls_button_pressed() -> void:
	controls_panel.visible = not controls_panel.visible


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _process(_delta: float) -> void:
	if _hero_preview_sprite == null:
		return
	var is_moving: bool = (
		Input.is_action_pressed("ui_right") or
		Input.is_action_pressed("ui_left") or
		Input.is_action_pressed("ui_up") or
		Input.is_action_pressed("ui_down")
	)
	var target_anim: String = "walk" if is_moving else "idle"
	if _hero_preview_sprite.animation != target_anim:
		_hero_preview_sprite.play(target_anim)


func _on_master_volume_slider_value_changed(value: float) -> void:
	var clamped: float = maxf(value, 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(clamped))


func _apply_ux_style() -> void:
	var menu_scale: float = _get_menu_scale()
	background.color = Color(0.045, 0.055, 0.09, 1.0)
	UiTextureUtils.apply_nearest_filter(self)
	UiTextureUtils.apply_nearest_filter(panel_container)
	UiTextureUtils.apply_nearest_filter(name_input)
	UiTextureUtils.apply_nearest_filter(master_slider)
	var textured_panel: StyleBoxTexture = UiTextureUtils.load_stylebox_texture("res://assets/ui/panels/panel_main_9slice.png", 24, StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT)
	if textured_panel != null:
		panel_container.add_theme_stylebox_override("panel", textured_panel)
	else:
		var panel_style: StyleBoxFlat = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.09, 0.12, 0.18, 0.95)
		panel_style.border_color = Color(0.28, 0.48, 0.7, 0.9)
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.corner_radius_top_left = 12
		panel_style.corner_radius_top_right = 12
		panel_style.corner_radius_bottom_right = 12
		panel_style.corner_radius_bottom_left = 12
		panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
		panel_style.shadow_size = 8
		panel_container.add_theme_stylebox_override("panel", panel_style)

	title_label.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(64.0, menu_scale, 1, 42.0)))
	title_label.add_theme_color_override("font_color", Color(0.85, 0.94, 1.0))
	title_label.add_theme_constant_override("outline_size", 3)
	title_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.9))
	main_vbox.add_theme_constant_override("separation", int(UiTextureUtils.scale_dimension(18.0, menu_scale, 1, 14.0)))

	for child in main_vbox.get_children():
		if child is Button:
			var btn := child as Button
			UiTextureUtils.apply_nearest_filter(btn)
			if btn.name in ["StartButton", "ContinueButton"]:
				_style_button(btn)
			elif btn.name in ["SettingsButton", "ControlsButton"]:
				_style_button_secondary(btn)
			elif btn.name == "QuitButton":
				_style_button_tertiary(btn)
			else:
				_style_button(btn)
		elif child is Label and child != title_label:
			var section_label: Label = child as Label
			section_label.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(18.0, menu_scale, 1, 14.0)))
			section_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.93))
			section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for nested_label in find_children("", "Label", true, false):
		if nested_label is Label and nested_label != title_label:
			var label_node: Label = nested_label as Label
			if str(label_node.name).begins_with("Controls"):
				label_node.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(16.0, menu_scale, 1, 13.0)))

	var input_tex: StyleBoxTexture = UiTextureUtils.load_stylebox_texture("res://assets/ui/panels/input_frame.png", 24, StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT)
	if input_tex != null:
		name_input.add_theme_stylebox_override("normal", input_tex)
		name_input.add_theme_stylebox_override("focus", input_tex)
	else:
		var input_normal: StyleBoxFlat = StyleBoxFlat.new()
		input_normal.bg_color = Color(0.07, 0.09, 0.13, 1.0)
		input_normal.border_color = Color(0.24, 0.36, 0.52, 1.0)
		input_normal.border_width_left = 1
		input_normal.border_width_top = 1
		input_normal.border_width_right = 1
		input_normal.border_width_bottom = 1
		input_normal.corner_radius_top_left = 8
		input_normal.corner_radius_top_right = 8
		input_normal.corner_radius_bottom_right = 8
		input_normal.corner_radius_bottom_left = 8
		name_input.add_theme_stylebox_override("normal", input_normal)

		var input_focus: StyleBoxFlat = input_normal.duplicate()
		input_focus.border_color = Color(0.35, 0.68, 1.0, 1.0)
		input_focus.border_width_left = 2
		input_focus.border_width_top = 2
		input_focus.border_width_right = 2
		input_focus.border_width_bottom = 2
		name_input.add_theme_stylebox_override("focus", input_focus)
	name_input.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	name_input.add_theme_color_override("font_placeholder_color", Color(0.5, 0.58, 0.7, 0.9))
	name_input.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(18.0, menu_scale, 1, 15.0)))
	name_input.custom_minimum_size = Vector2(0, UiTextureUtils.scale_dimension(44.0, menu_scale, 2, 38.0))
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER

	_style_slider(master_slider)
	master_slider.modulate = Color(0.75, 0.86, 1.0, 1.0)


func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = _get_viewport_size()
	var menu_scale: float = _get_menu_scale()
	var panel_width: float = clampf(viewport_size.x * 0.34, UiTextureUtils.scale_dimension(460.0, menu_scale, 4, 420.0), UiTextureUtils.scale_dimension(620.0, menu_scale, 4, 620.0))
	var panel_height: float = clampf(viewport_size.y * 0.7, UiTextureUtils.scale_dimension(560.0, menu_scale, 4, 520.0), UiTextureUtils.scale_dimension(760.0, menu_scale, 4, 760.0))
	panel_container.custom_minimum_size = Vector2(panel_width, panel_height)
	panel_container.size = panel_container.custom_minimum_size
	panel_container.get_parent().set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel_margin: MarginContainer = panel_container.get_node("MarginContainer") as MarginContainer
	var inset: int = int(UiTextureUtils.scale_dimension(40.0, menu_scale, 2, 28.0))
	panel_margin.add_theme_constant_override("margin_left", inset)
	panel_margin.add_theme_constant_override("margin_top", inset)
	panel_margin.add_theme_constant_override("margin_right", inset)
	panel_margin.add_theme_constant_override("margin_bottom", inset)
	if _hero_preview_sprite != null and _hero_preview_source_side > 1.0:
		var preview_target_px: float = float(ConfigService.get_value("visual.target_px.menu_preview", 280.0)) * menu_scale
		var preview_scale: float = preview_target_px / _hero_preview_source_side
		_hero_preview_sprite.scale = Vector2(preview_scale, preview_scale)
		if _hero_preview_glow != null:
			_hero_preview_glow.scale = Vector2(preview_scale * 0.9, preview_scale * 0.4)
	if _hero_preview_node != null:
		_hero_preview_node.position = Vector2(viewport_size.x * 0.81, viewport_size.y * 0.58)


func _style_button(button: Button) -> void:
	var menu_scale: float = _get_menu_scale()
	button.custom_minimum_size = Vector2(0, UiTextureUtils.scale_dimension(60.0, menu_scale, 2, 48.0))
	button.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(20.0, menu_scale, 1, 16.0)))

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
		button.add_theme_color_override("font_pressed_color", Color(0.82, 0.9, 1.0))
		button.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.58))
		return

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.17, 0.25, 1.0)
	normal.border_color = Color(0.28, 0.42, 0.62, 1.0)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_right = 8
	normal.corner_radius_bottom_left = 8

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.18, 0.26, 0.36, 1.0)
	hover.border_color = Color(0.4, 0.64, 0.92, 1.0)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(0.09, 0.13, 0.19, 1.0)
	pressed.border_color = Color(0.34, 0.52, 0.76, 1.0)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	disabled.border_color = Color(0.22, 0.24, 0.3, 0.9)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.82, 0.9, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.58))


func _style_button_secondary(button: Button) -> void:
	var menu_scale: float = _get_menu_scale()
	button.custom_minimum_size = Vector2(0, UiTextureUtils.scale_dimension(44.0, menu_scale, 2, 38.0))
	button.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(16.0, menu_scale, 1, 13.0)))
	var normal_tex: StyleBoxTexture = UiTextureUtils.load_stylebox_texture("res://assets/ui/panels/button_secondary_normal.png", 24, StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT)
	var hover_tex: StyleBoxTexture = UiTextureUtils.load_stylebox_texture("res://assets/ui/panels/button_secondary_hover.png", 24, StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT)
	var pressed_tex: StyleBoxTexture = UiTextureUtils.load_stylebox_texture("res://assets/ui/panels/button_secondary_pressed.png", 24, StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT)
	if normal_tex != null and hover_tex != null and pressed_tex != null:
		button.add_theme_stylebox_override("normal", normal_tex)
		button.add_theme_stylebox_override("hover", hover_tex)
		button.add_theme_stylebox_override("pressed", pressed_tex)
		button.add_theme_color_override("font_color", Color(0.78, 0.88, 0.98))
		button.add_theme_color_override("font_hover_color", Color(0.92, 0.97, 1.0))
		return
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.13, 0.20, 0.9)
	normal.border_color = Color(0.22, 0.34, 0.52, 0.85)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 7
	normal.corner_radius_top_right = 7
	normal.corner_radius_bottom_right = 7
	normal.corner_radius_bottom_left = 7
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.13, 0.20, 0.30, 0.95)
	hover.border_color = Color(0.34, 0.52, 0.76, 1.0)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(0.07, 0.10, 0.16, 0.9)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.78, 0.88, 0.98))
	button.add_theme_color_override("font_hover_color", Color(0.92, 0.97, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.70, 0.80, 0.92))


func _style_button_tertiary(button: Button) -> void:
	var menu_scale: float = _get_menu_scale()
	button.custom_minimum_size = Vector2(0, UiTextureUtils.scale_dimension(40.0, menu_scale, 2, 34.0))
	button.add_theme_font_size_override("font_size", int(UiTextureUtils.scale_dimension(15.0, menu_scale, 1, 12.0)))
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	var hover: StyleBoxFlat = StyleBoxFlat.new()
	hover.bg_color = Color(0.15, 0.22, 0.32, 0.5)
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_right = 6
	hover.corner_radius_bottom_left = 6
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_color_override("font_color", Color(0.52, 0.58, 0.66))
	button.add_theme_color_override("font_hover_color", Color(0.72, 0.80, 0.90))


func _style_slider(slider: HSlider) -> void:
	var track_tex: StyleBoxTexture = UiTextureUtils.load_stylebox_texture("res://assets/ui/panels/slider_track.png", 24, StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT)
	if track_tex != null:
		slider.add_theme_stylebox_override("slider", track_tex)
		slider.add_theme_stylebox_override("grabber_area", track_tex)
		slider.add_theme_stylebox_override("grabber_area_highlight", track_tex)
	var thumb: Texture2D = _load_icon("res://assets/ui/panels/slider_thumb.png")
	if thumb != null:
		slider.add_theme_icon_override("grabber", thumb)
		slider.add_theme_icon_override("grabber_highlight", thumb)
		slider.add_theme_icon_override("grabber_disabled", thumb)


func _load_icon(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _wrap_control_with_icon(control: Control, icon_path: String, icon_size: float, separation: int = 6) -> void:
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


func _apply_menu_icons() -> void:
	var button_icon: Texture2D = _load_icon("res://assets/ui/icons/icon_chest.png")
	if button_icon != null:
		continue_action_button.icon = button_icon
	start_button.icon = _load_icon("res://assets/ui/icons/icon_player_hero.png")
	controls_button.icon = _load_icon("res://assets/ui/icons/icon_dash.png")

	var control_icon_size: float = float(ConfigService.get_value("visual.hud.label_icon_size", 24)) * _get_menu_scale()
	_wrap_control_with_icon(controls_dash_label, "res://assets/ui/icons/icon_dash.png", control_icon_size)
	_wrap_control_with_icon(controls_bomb_label, "res://assets/ui/icons/icon_bomb.png", control_icon_size)
	_wrap_control_with_icon(controls_heal_label, "res://assets/ui/icons/icon_heal.png", control_icon_size)
	_wrap_control_with_icon(controls_target_label, "res://assets/ui/icons/icon_targeting.png", control_icon_size)
	_wrap_control_with_icon(controls_perk_label, "res://assets/ui/icons/icon_perk_tree.png", control_icon_size)


func _setup_hero_preview() -> void:
	# Prefer dedicated character preview assets, fall back to main animation folder
	var preview_idle_path: String = "res://assets/ui/backgrounds/character_previews/idle_south/frame_000.png"
	var main_idle_path: String = "res://assets/characters/genihero_ui/animations/breathing-idle/south/frame_000.png"
	var use_preview: bool = ResourceLoader.exists(preview_idle_path)
	var idle_base: String = "res://assets/ui/backgrounds/character_previews/idle_south/frame_%03d.png" if use_preview else "res://assets/characters/genihero_ui/animations/breathing-idle/south/frame_%03d.png"
	var walk_base: String = "res://assets/ui/backgrounds/character_previews/walk_south/frame_%03d.png"

	if not use_preview and not ResourceLoader.exists(main_idle_path):
		return

	# Hero sprite container positioned to the right of the panel
	var hero_container: Control = Control.new()
	hero_container.name = "HeroPreviewContainer"
	hero_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hero_container)

	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.name = "HeroPreviewSprite"
	var preview_scale: float = ConfigService.get_value("visual.sprite_scale.menu_preview", 4.0)
	var preview_target_px: float = ConfigService.get_value("visual.target_px.menu_preview", 280.0)
	var preview_first_path: String = idle_base % 0
	if ResourceLoader.exists(preview_first_path):
		var preview_tex: Texture2D = load(preview_first_path) as Texture2D
		if preview_tex != null:
			_hero_preview_source_side = maxf(float(preview_tex.get_width()), float(preview_tex.get_height()))
			if _hero_preview_source_side > 1.0:
				preview_scale = preview_target_px / _hero_preview_source_side
	sprite.scale = Vector2(preview_scale, preview_scale)

	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")

	frames.add_animation("idle")
	frames.set_animation_speed("idle", 7.0)
	frames.set_animation_loop("idle", true)
	for i in range(6):
		var path: String = idle_base % i
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex:
				frames.add_frame("idle", tex)

	# Add walk animation from character previews
	frames.add_animation("walk")
	frames.set_animation_speed("walk", 8.0)
	frames.set_animation_loop("walk", true)
	for i in range(6):
		var wpath: String = walk_base % i
		if ResourceLoader.exists(wpath):
			var tex: Texture2D = load(wpath) as Texture2D
			if tex:
				frames.add_frame("walk", tex)

	sprite.sprite_frames = frames
	sprite.play("idle")

	# Position: below center, slightly right - subtle decoration
	var canvas_container: Node2D = Node2D.new()
	canvas_container.name = "HeroPreviewNode"
	add_child(canvas_container)
	_hero_preview_node = canvas_container

	# Platform glow beneath hero
	var glow_path: String = "res://assets/ui/backgrounds/hero_platform_glow.png"
	if ResourceLoader.exists(glow_path):
		var glow_tex: Texture2D = load(glow_path) as Texture2D
		if glow_tex != null:
			var glow_sprite: Sprite2D = Sprite2D.new()
			glow_sprite.texture = glow_tex
			glow_sprite.position = Vector2(0, 28)
			glow_sprite.scale = Vector2(preview_scale * 0.9, preview_scale * 0.4)
			glow_sprite.modulate = Color(0.2, 0.8, 1.0, 0.3)
			canvas_container.add_child(glow_sprite)
			_hero_preview_glow = glow_sprite
	canvas_container.add_child(sprite)
	_hero_preview_sprite = sprite

