extends Node2D

## Pixellab Wang tileset arka planı — koyu renk + çeşitlilik.
## Atlas: pixellab_topdown_5302d681.png (128×128 → 4×4 grid, 32×32)
## Terrain: 0=lower (alien planet, yeşil)  1=upper (moon surface, gri)
## Bitmask: bit3=NW  bit2=NE  bit1=SW  bit0=SE

@export var atlas_texture: Texture2D = preload("res://assets/backgrounds/pixellab_topdown_5302d681.png")
@export var tile_size: int = 32
## Büyük arazi yamalarının ölçeği (küçük = büyük yamalar)
@export var terrain_frequency: float = 0.06
@export var terrain_seed: int = 7
## Renk ve çevirme varyasyonu için ikinci gürültü ölçeği
@export var detail_frequency: float = 0.31
@export var viewport_margin_tiles: int = 3

# ── Arazi renk paleteri (koyu/karanlık ton) ──────────────────────────────────
# Lower = alien planet: koyu zeytin/zümrüt
const _LOWER_COLORS: Array[Color] = [
	Color(0.28, 0.38, 0.22, 1.0),
	Color(0.22, 0.32, 0.18, 1.0),
	Color(0.32, 0.44, 0.24, 1.0),
]
# Upper = moon surface: koyu çelik/slate
const _UPPER_COLORS: Array[Color] = [
	Color(0.30, 0.32, 0.38, 1.0),
	Color(0.22, 0.24, 0.30, 1.0),
	Color(0.36, 0.36, 0.44, 1.0),
]
# Geçiş tile'ı için ortak karanlık ton
const _TRANS_COLOR: Color = Color(0.26, 0.28, 0.26, 1.0)

# Bitmaske → Rect2 (metadata bounding_box)
var _tile_rects: Dictionary = {
	0b0000: Rect2( 64, 32, 32, 32),  # L L L L
	0b0001: Rect2( 96, 32, 32, 32),  # L L L U
	0b0010: Rect2( 64, 64, 32, 32),  # L L U L
	0b0011: Rect2( 32, 64, 32, 32),  # L L U U
	0b0100: Rect2( 96, 32, 32, 32),  # L U L L  (mirror of 0001)
	0b0101: Rect2( 96, 64, 32, 32),  # L U L U
	0b0110: Rect2( 64, 64, 32, 32),  # L U U L  (approx)
	0b0111: Rect2( 96, 96, 32, 32),  # L U U U
	0b1000: Rect2( 64, 64, 32, 32),  # U L L L  (approx)
	0b1001: Rect2( 64, 32, 32, 32),  # U L L U  (diagonal fallback)
	0b1010: Rect2( 32,  0, 32, 32),  # U L U L
	0b1011: Rect2(  0, 64, 32, 32),  # U L U U
	0b1100: Rect2( 32, 64, 32, 32),  # U U L L
	0b1101: Rect2(  0, 64, 32, 32),  # U U L U
	0b1110: Rect2( 96, 96, 32, 32),  # U U U L
	0b1111: Rect2(  0, 96, 32, 32),  # U U U U
}

var _noise: FastNoiseLite = FastNoiseLite.new()
var _detail: FastNoiseLite = FastNoiseLite.new()


func _ready() -> void:
	_noise.seed = terrain_seed
	_noise.frequency = terrain_frequency
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_detail.seed = terrain_seed + 31
	_detail.frequency = detail_frequency
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX


func _terrain_at(vx: int, vy: int) -> int:
	return 1 if _noise.get_noise_2d(float(vx), float(vy)) > 0.0 else 0


# Tile koordinatına göre deterministik renk + çevirme seçimi
func _tile_color(tx: int, ty: int, mask: int) -> Color:
	var d: float = _detail.get_noise_2d(float(tx), float(ty))  # -1..1
	var idx: int = int(abs(d) * 2.9)  # 0,1,2

	# Saf lower ya da saf upper seçimi
	if mask == 0b0000:
		return _LOWER_COLORS[idx]
	if mask == 0b1111:
		return _UPPER_COLORS[idx]
	# Geçiş tile → lower/upper karışımına göre interpolasyon
	var upper_bits: int = bin_count(mask)
	var t: float = float(upper_bits) / 4.0
	var lo: Color = _LOWER_COLORS[idx]
	var hi: Color = _UPPER_COLORS[idx]
	return lo.lerp(hi, t)


func bin_count(v: int) -> int:
	var c: int = 0
	while v:
		c += v & 1
		v >>= 1
	return c


# Tile'ı isteğe bağlı yatay/dikey çevirerek çizer (varyasyon için)
func _draw_tile(src: Rect2, dst: Rect2, flip_h: bool, flip_v: bool, color: Color) -> void:
	if not flip_h and not flip_v:
		draw_texture_rect_region(atlas_texture, dst, src, color)
		return
	var cx: float = dst.position.x + dst.size.x * 0.5
	var cy: float = dst.position.y + dst.size.y * 0.5
	draw_set_transform(Vector2(cx, cy), 0.0,
		Vector2(-1.0 if flip_h else 1.0, -1.0 if flip_v else 1.0))
	var centered: Rect2 = Rect2(
		Vector2(-dst.size.x * 0.5, -dst.size.y * 0.5), dst.size)
	draw_texture_rect_region(atlas_texture, centered, src, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if atlas_texture == null or tile_size <= 0:
		return
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var half_w: float = vp_size.x * 0.5
	var half_h: float = vp_size.y * 0.5
	var cam_pos: Vector2 = cam.global_position
	var ts: float = float(tile_size)

	var min_tx: int = int(floor((cam_pos.x - half_w) / ts)) - viewport_margin_tiles
	var max_tx: int = int(ceil( (cam_pos.x + half_w) / ts)) + viewport_margin_tiles
	var min_ty: int = int(floor((cam_pos.y - half_h) / ts)) - viewport_margin_tiles
	var max_ty: int = int(ceil( (cam_pos.y + half_h) / ts)) + viewport_margin_tiles

	for ty in range(min_ty, max_ty + 1):
		for tx in range(min_tx, max_tx + 1):
			var nw: int = _terrain_at(tx,     ty    )
			var ne: int = _terrain_at(tx + 1, ty    )
			var sw: int = _terrain_at(tx,     ty + 1)
			var se: int = _terrain_at(tx + 1, ty + 1)

			var mask: int = (nw << 3) | (ne << 2) | (sw << 1) | se
			var src: Rect2 = _tile_rects[mask]
			var dst: Rect2 = Rect2(Vector2(tx * ts, ty * ts), Vector2(ts, ts))
			var color: Color = _tile_color(tx, ty, mask)

			# Hash bazlı deterministic flip → görsel çeşitlilik
			var h: int = (tx * 2654435761 ^ ty * 2246822519) & 0xFFFF
			var flip_h: bool = (h & 1) != 0
			var flip_v: bool = (h & 2) != 0
			# Geçiş tile'larını çevirme (kenarlar farklı terrain'e sahip, flip bozabilir)
			if mask != 0b0000 and mask != 0b1111:
				flip_h = false
				flip_v = false

			_draw_tile(src, dst, flip_h, flip_v, color)