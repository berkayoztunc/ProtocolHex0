class_name PerkCard
extends Sprite2D

signal pressed(perk_id: String)

var perk_id: String = ""
var is_selectable: bool = false
var is_locked: bool = false
var is_unlocked: bool = false
var is_maxed: bool = false

var _name_label: Label
var _stack_label: Label
var _base_modulate: Color = Color.WHITE
var _is_hovered: bool = false
var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	# Do not touch scale/positions set in the editor
	# Just get label references
	_name_label = get_node_or_null("NameLabel") as Label
	_stack_label = get_node_or_null("StackLabel") as Label
	
	# Area2D + CollisionShape2D setup
	var area := get_node_or_null("Area2D") as Area2D
	if area:
		area.input_event.connect(_on_area_input_event)
		area.mouse_entered.connect(_on_area_mouse_entered)
		area.mouse_exited.connect(_on_area_mouse_exited)


func get_card_size() -> Vector2:
	# Rendered actual size = region size × scale
	if texture:
		var ts: Vector2
		if region_enabled:
			ts = region_rect.size
		else:
			ts = texture.get_size()
		return ts * Vector2(absf(scale.x), absf(scale.y))
	return Vector2(104.0, 120.0)


func setup(id: String, perk_data: Dictionary, stacks: int, max_stacks: int, prereqs_met: bool, selectable: bool) -> void:
	perk_id = id
	is_selectable = selectable
	is_locked = not prereqs_met
	is_unlocked = stacks > 0
	is_maxed = max_stacks > 0 and stacks >= max_stacks

	if _name_label:
		_name_label.text = str(perk_data.get("name", id))
	if _stack_label:
		_update_stack_text(stacks, max_stacks, selectable)
	_update_visual()


func _update_stack_text(stacks: int, max_stacks: int, selectable: bool) -> void:
	var base_cost := int(ConfigService.get_value("upgrades.perk_costs.%s" % perk_id, 1))
	var next_cost := base_cost * (stacks + 1)
	var text := ""

	if is_locked:
		text = "🔒 ◇ %d" % next_cost
	elif is_maxed:
		if max_stacks == 1:
			text = "◆ Aktif"
		else:
			text = "◆ MAX (%d/%d)" % [stacks, max_stacks]
	elif is_unlocked:
		if max_stacks > 0:
			text = "◇ %d | %d/%d" % [next_cost, stacks, max_stacks]
		elif max_stacks < 0:
			text = "◇ %d | ×%d" % [next_cost, stacks]
		else:
			text = "✓"
	else:
		if max_stacks > 0:
			text = "◇ %d | 0/%d" % [next_cost, max_stacks]
		else:
			text = "◇ %d" % next_cost

	if selectable:
		text = "◆ %d — SELECT" % next_cost

	_stack_label.text = text


func _update_visual() -> void:
	if is_locked:
		_base_modulate = Color(0.5, 0.5, 0.5, 0.7)
	elif is_selectable:
		_base_modulate = Color(1.0, 1.0, 0.85, 1.0)
	elif is_maxed:
		_base_modulate = Color(1.0, 0.9, 0.4, 1.0)
	elif is_unlocked:
		_base_modulate = Color(0.8, 1.0, 0.8, 1.0)
	else:
		_base_modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# Apply hover effect if hovered
	if _is_hovered:
		modulate = _base_modulate.lightened(0.25)
	else:
		modulate = _base_modulate


func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_selectable:
			pressed.emit(perk_id)
			get_viewport().set_input_as_handled()
			_play_click_feedback()
		else:
			# Non-selectable cards still show feedback
			_play_disabled_feedback()


func _on_area_mouse_entered() -> void:
	_is_hovered = true
	modulate = _base_modulate.lightened(0.25)


func _on_area_mouse_exited() -> void:
	_is_hovered = false
	modulate = _base_modulate


func _play_click_feedback() -> void:
	# Scale pulse animation for successful click
	_base_scale = scale
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", _base_scale * 1.1, 0.1)
	tween.tween_property(self, "scale", _base_scale, 0.1)


func _play_disabled_feedback() -> void:
	# Slight shake/pulse for non-selectable cards
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	var orig_x := position.x
	tween.tween_property(self, "position:x", orig_x - 3, 0.05)
	tween.tween_property(self, "position:x", orig_x + 3, 0.05)
	tween.tween_property(self, "position:x", orig_x, 0.05)


## Returns the card bounds in global (viewport) coordinates.
func get_card_rect_global() -> Rect2:
	var s := get_card_size()
	return Rect2(global_position - s * 0.5, s)
