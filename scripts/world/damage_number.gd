extends Node2D

var duration: float = 0.55

func setup(amount: int, is_crit: bool = false) -> void:
	var label: Label = $Label
	label.text = str(amount)
	if is_crit:
		label.text = str(amount) + "!"
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		label.add_theme_font_size_override("font_size", 38)
		scale = Vector2(1.28, 1.28)
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
		label.add_theme_font_size_override("font_size", 26)

func _ready() -> void:
	var float_offset: Vector2 = Vector2(randf_range(-16, 16), -64)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_delay(duration * 0.4)
	tween.tween_property(self, "position", position + float_offset, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if scale.x > 1.0:
		tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(queue_free)
