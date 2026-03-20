extends Control

const SLOT_FRAME_PATH := "res://assets/ui/panels/slot_frame_active.png"
const SLOT_SIZE := 64
const LABEL_HEIGHT := 20

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
	var card_h: int = SLOT_SIZE + LABEL_HEIGHT
	var root := Control.new()
	root.custom_minimum_size = Vector2(SLOT_SIZE, card_h)

	# Sprite2D: slot frame
	var frame := Sprite2D.new()
	frame.name = "Frame"
	var frame_tex: Texture2D = _load_tex(SLOT_FRAME_PATH)
	if frame_tex != null:
		frame.texture = frame_tex
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.centered = true
	frame.position = Vector2(SLOT_SIZE * 0.5, SLOT_SIZE * 0.5)
	if not is_active:
		frame.modulate = Color(0.55, 0.60, 0.70, 0.85)
	root.add_child(frame)

	# Sprite2D: weapon icon
	var wid: String = str(weapon.get("id", "")).to_lower().replace(" ", "_")
	var icon_tex: Texture2D = _load_tex("res://assets/ui/icons/weapon_%s.png" % wid)
	if icon_tex != null:
		var icon := Sprite2D.new()
		icon.name = "Icon"
		icon.texture = icon_tex
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.centered = true
		icon.position = Vector2(SLOT_SIZE * 0.5, SLOT_SIZE * 0.5)
		var tex_size: Vector2 = icon_tex.get_size()
		var target: float = SLOT_SIZE * 0.55
		var s: float = target / maxf(tex_size.x, tex_size.y)
		icon.scale = Vector2(s, s)
		if not is_active:
			icon.modulate = Color(0.65, 0.65, 0.70, 1.0)
		root.add_child(icon)

	# Key badge top-left for active slots with a binding
	var key_text: String = str(weapon.get("key", ""))
	if is_active and not key_text.is_empty():
		var badge := Label.new()
		badge.name = "KeyBadge"
		badge.text = key_text
		badge.add_theme_font_size_override("font_size", 8)
		badge.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9, 1.0))
		badge.position = Vector2(3, 3)
		badge.size = Vector2(SLOT_SIZE - 6, 12)
		root.add_child(badge)

	# Cooldown dim overlay when not ready
	var is_ready: bool = bool(weapon.get("ready", true))
	if is_active and not is_ready:
		var dim := ColorRect.new()
		dim.name = "CooldownDim"
		dim.color = Color(0.0, 0.0, 0.0, 0.55)
		dim.position = Vector2(0, 0)
		dim.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		root.add_child(dim)

	# Label: weapon name below slot
	var lbl := Label.new()
	lbl.name = "NameLabel"
	var name_text: String = str(weapon.get("name", ""))
	if is_active and key_text.is_empty():
		lbl.text = "[Main]\n%s" % name_text
	else:
		lbl.text = name_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.position = Vector2(0, SLOT_SIZE + 2)
	lbl.size = Vector2(SLOT_SIZE, LABEL_HEIGHT)
	if not is_active:
		lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.65, 1.0))
	root.add_child(lbl)

	return root


func _load_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
