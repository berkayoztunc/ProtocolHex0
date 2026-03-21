extends Node2D

## Pixellab flat-tile arka planı — damasız, tam kaplama.
## Tüm tile'lar flat_tile_*.png → seamless, beyaz kenarsız.
## 12 yeni tile gelince flat_new_*.png de yüklenir, toplam 24 varyant.

## Ekranda her tile'ın piksel boyutu — kaynak PNG 32px, integer kat kullan (32, 64, 128…)
@export var tile_size: int = 128
## Büyük biome yamalarının ölçeği (küçük = büyük yamalar)
@export var terrain_frequency: float = 0.025
@export var terrain_seed: int = 7
## Küçük renk varyasyonu gürültüsü
@export var detail_frequency: float = 0.18
## Genel parlaklık (0=siyah, 1=tam orijinal)
@export var brightness: float = 0.82
@export var viewport_margin_tiles: int = 4

# ── Renk paleti — doğal, az doygunluk ─────────────────────────────────────
const _GROUP_A_COLORS: Array[Color] = [  # organik zemin (forest/dirt/soil)
	Color(0.42, 0.38, 0.28, 1.0),
	Color(0.36, 0.32, 0.23, 1.0),
	Color(0.48, 0.43, 0.31, 1.0),
]
const _GROUP_B_COLORS: Array[Color] = [  # taş/metal zemin (stone/metal/concrete)
	Color(0.35, 0.35, 0.38, 1.0),
	Color(0.28, 0.28, 0.32, 1.0),
	Color(0.40, 0.40, 0.44, 1.0),
]

# 2D noise: hangi bölge group A/B olacak
var _terrain_noise: FastNoiseLite = FastNoiseLite.new()
# 2D noise: renk varyantı (3 renk arası)
var _detail_noise: FastNoiseLite = FastNoiseLite.new()
# 2D noise: hangi tile varyantı (6 tile arası)
var _variant_noise: FastNoiseLite = FastNoiseLite.new()

## group A tile'ları (flat_tile_0..5 = eski, flat_new_0..5 = yeni organic)
var _tiles_a: Array[Texture2D] = []
## group B tile'ları (flat_tile_... = eski stone/metal, flat_new_6..11 = yeni)
var _tiles_b: Array[Texture2D] = []


func _ready() -> void:
	# Pixel-perfect çizim — kenar bleeding'i tamamen engeller
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_terrain_noise.seed = terrain_seed
	_terrain_noise.frequency = terrain_frequency
	_terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_terrain_noise.fractal_octaves = 3

	_detail_noise.seed = terrain_seed + 31
	_detail_noise.frequency = detail_frequency
	_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	_variant_noise.seed = terrain_seed + 97
	_variant_noise.frequency = 0.41
	_variant_noise.noise_type = FastNoiseLite.TYPE_VALUE

	# Group A: organik — eski flat_tile_0..2 + yeni flat_new_0..5
	for i in [0, 1, 2]:
		var t: Texture2D = _try_load("res://assets/backgrounds/flat_tile_%d.png" % i)
		if t:
			_tiles_a.append(t)
	for i in range(6):
		var t: Texture2D = _try_load("res://assets/backgrounds/flat_new_%d.png" % i)
		if t:
			_tiles_a.append(t)

	# Group B: taş/metal — eski flat_tile_3..5 + yeni flat_new_6..11
	for i in [3, 4, 5]:
		var t: Texture2D = _try_load("res://assets/backgrounds/flat_tile_%d.png" % i)
		if t:
			_tiles_b.append(t)
	for i in range(6, 12):
		var t: Texture2D = _try_load("res://assets/backgrounds/flat_new_%d.png" % i)
		if t:
			_tiles_b.append(t)

	# Fallback: eğer hiçbir şey yoksa placeholder
	if _tiles_a.is_empty() and _tiles_b.is_empty():
		push_warning("BackgroundTiler: hiç tile yüklenemedi!")


func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var ts: float = float(tile_size)
	# Grid hesabı için kamera pozisyonunu tam piksel'e snap'le
	var cam_pos: Vector2 = cam.global_position.round()

	var min_tx: int = int(floor((cam_pos.x - vp_size.x * 0.5) / ts)) - viewport_margin_tiles
	var max_tx: int = int(ceil( (cam_pos.x + vp_size.x * 0.5) / ts)) + viewport_margin_tiles
	var min_ty: int = int(floor((cam_pos.y - vp_size.y * 0.5) / ts)) - viewport_margin_tiles
	var max_ty: int = int(ceil( (cam_pos.y + vp_size.y * 0.5) / ts)) + viewport_margin_tiles

	# cam_frac = kameranın round()'dan farkı (-0.5..0.5)
	# draw_set_transform(cam_frac) → tile'lar her zaman tam integer screen pixel'a düşer
	# İspat: screen_x = tx*ts + cam_frac - cam.x + vp/2
	#              = tx*ts + (cam.x - round(cam.x)) - cam.x + vp/2
	#              = tx*ts - round(cam.x) + vp/2  ← tüm terimler integer ✓
	var cam_frac: Vector2 = cam.global_position - cam_pos
	draw_set_transform(cam_frac, 0.0, Vector2.ONE)

	for ty in range(min_ty, max_ty + 1):
		for tx in range(min_tx, max_tx + 1):
			var terrain_v: float = _terrain_noise.get_noise_2d(float(tx), float(ty))
			var is_b: bool = terrain_v > 0.0

			var pool: Array[Texture2D] = _tiles_b if is_b else _tiles_a
			if pool.is_empty():
				pool = _tiles_a if pool == _tiles_b else _tiles_b
			if pool.is_empty():
				continue

			# Deterministik tile + renk varyantı
			var vn: float = _variant_noise.get_noise_2d(float(tx), float(ty))
			var vi: int = int(abs(vn) * float(pool.size() - 1) + 0.5) % pool.size()
			var tex: Texture2D = pool[vi]

			var dn: float = _detail_noise.get_noise_2d(float(tx), float(ty))
			var ci: int = int(abs(dn) * 2.9)
			var palette: Array[Color] = _GROUP_B_COLORS if is_b else _GROUP_A_COLORS
			var base: Color = palette[ci]
			var color: Color = Color(base.r * brightness, base.g * brightness, base.b * brightness, 1.0)

			# 2px simetrik overlap: her tile 4 yönde de 2px komşusunun üstüne biner
			# → GPU rasterizasyon gap'leri tamamen kapanır, seamless tile'larda görünmez
			const PAD: float = 2.0
			var pos: Vector2 = Vector2(tx * ts - PAD, ty * ts - PAD)
			var dst: Rect2 = Rect2(pos, Vector2(ts + PAD * 2.0, ts + PAD * 2.0))
			draw_texture_rect(tex, dst, false, color)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
