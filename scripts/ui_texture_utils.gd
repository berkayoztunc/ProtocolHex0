extends RefCounted

class_name UiTextureUtils

static func snap_dimension(value: float, base: int) -> float:
	var scale: int = maxi(1, int(round(value / float(base))))
	return float(base * scale)


static func get_viewport_scale(viewport_size: Vector2, base_size: Vector2 = Vector2(1600.0, 900.0), min_scale: float = 0.75, max_scale: float = 1.2) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	var width_ratio: float = viewport_size.x / maxf(base_size.x, 1.0)
	var height_ratio: float = viewport_size.y / maxf(base_size.y, 1.0)
	return clampf(minf(width_ratio, height_ratio), min_scale, max_scale)


static func scale_dimension(value: float, scale: float, step: int = 1, minimum: float = 0.0) -> float:
	var scaled: float = maxf(minimum, value * scale)
	if step <= 1:
		return roundf(scaled)
	return roundf(scaled / float(step)) * float(step)


static func apply_nearest_filter(node: CanvasItem) -> void:
	if node != null:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


static func load_stylebox_texture(path: String, texture_margin: int = 0, tile_mode: int = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH) -> StyleBoxTexture:
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return null
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = tex
	style.axis_stretch_horizontal = tile_mode
	style.axis_stretch_vertical = tile_mode
	if texture_margin > 0:
		style.texture_margin_left = texture_margin
		style.texture_margin_top = texture_margin
		style.texture_margin_right = texture_margin
		style.texture_margin_bottom = texture_margin
	return style


static func load_center_strip_stylebox_texture(path: String, strip_height: int) -> StyleBoxTexture:
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return null
	var tex_size: Vector2 = tex.get_size()
	if tex_size.y < strip_height:
		return null
	var strip_y: int = int((tex_size.y - strip_height) * 0.5)
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(0.0, float(strip_y), tex_size.x, float(strip_height))
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = atlas
	return style