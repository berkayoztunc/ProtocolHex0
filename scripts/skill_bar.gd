extends Control

@onready var active_container: HBoxContainer = $Panel/Margin/VBox/ActiveRow
@onready var passive_container: HBoxContainer = $Panel/Margin/VBox/PassiveRow


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func update_weapons(weapons_data: Array) -> void:
	for child in active_container.get_children():
		child.queue_free()
	for child in passive_container.get_children():
		child.queue_free()

	var has_any: bool = false
	for entry in weapons_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var weapon: Dictionary = entry as Dictionary
		var key_text: String = str(weapon.get("key", ""))
		var is_active: bool = not key_text.is_empty() or bool(weapon.get("is_held", false))
		var card := _create_weapon_card(weapon, is_active)
		if is_active:
			active_container.add_child(card)
		else:
			passive_container.add_child(card)
		has_any = true

	visible = has_any


func _create_weapon_card(weapon: Dictionary, is_active: bool) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 44)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 4)
	card.add_child(margin)

	var label := Label.new()
	var name_text: String = str(weapon.get("name", "Unknown"))
	var key_text: String = str(weapon.get("key", ""))
	var ready: bool = bool(weapon.get("ready", true))
	var state_text: String = ""
	if is_active:
		if key_text.is_empty():
			state_text = "[Main]"
		else:
			state_text = key_text
		if not ready:
			state_text += " • CD"
	label.text = "%s %s" % [state_text, name_text] if is_active else name_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(label)

	return card
