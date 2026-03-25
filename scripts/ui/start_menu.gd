extends Control

@onready var name_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NameInput
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton
@onready var settings_panel: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsPanel
@onready var controls_panel: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ControlsPanel
@onready var master_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsPanel/MasterVolumeSlider
@onready var background: TextureRect = $Background
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
@onready var version_label: Label = $VersionLabel
@onready var detail_container: CenterContainer = $DetailContainer
@onready var detail_vbox: VBoxContainer = $DetailContainer/PanelContainer/MarginContainer/VBoxContainer



func _ready() -> void:
	name_input.text = Session.player_name
	continue_button.disabled = not Session.has_last_run()
	settings_panel.visible = false
	controls_panel.visible = false
	detail_container.visible = false
	if settings_panel.get_parent() != detail_vbox:
		var settings_parent: Node = settings_panel.get_parent()
		if settings_parent != null:
			settings_parent.remove_child(settings_panel)
		detail_vbox.add_child(settings_panel)
	if controls_panel.get_parent() != detail_vbox:
		var controls_parent: Node = controls_panel.get_parent()
		if controls_parent != null:
			controls_parent.remove_child(controls_panel)
		detail_vbox.add_child(controls_panel)
	settings_panel.visible = false
	controls_panel.visible = false
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))


func _on_start_button_pressed() -> void:
	Session.player_name = name_input.text.strip_edges()
	if Session.player_name.is_empty():
		Session.player_name = "Hero"
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _on_continue_button_pressed() -> void:
	if not Session.has_last_run():
		return
	Session.start_continue_run()
	MockApiClient.queue_event("run_continue", {"player_name": Session.player_name})
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_settings_button_pressed() -> void:
	var show_settings: bool = not (detail_container.visible and settings_panel.visible)
	detail_container.visible = show_settings
	settings_panel.visible = show_settings
	controls_panel.visible = false


func _on_controls_button_pressed() -> void:
	var show_controls: bool = not (detail_container.visible and controls_panel.visible)
	detail_container.visible = show_controls
	controls_panel.visible = show_controls
	settings_panel.visible = false


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_master_volume_slider_value_changed(value: float) -> void:
	var clamped: float = maxf(value, 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(clamped))


func _on_upgrade_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/base_perk_upgrade.tscn")


func _apply_ux_style() -> void:
	pass
