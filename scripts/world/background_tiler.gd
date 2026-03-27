extends Node2D

## Pixellab flat-tile background — seamless, full coverage.
## All tiles flat_tile_*.png → seamless, no white borders.
## When 12 new tiles arrive, flat_new_*.png is also loaded, 24 variants total.

## ── Hex tile background mode ──────────────────────────────────────────────────────
## When true, only bigtile1.png / bigtile2.png are used.
@export var use_hex_tiles: bool = false
## Hash seed — change to get a different plane layout
@export var hex_random_seed: int = 12345
## Brightness multiplier (1.0 = original, lower = darker)
@export var hex_brightness: float = 0.68
## bigtile2 appearance chance (0.0–1.0) — rare
@export var bigtile2_chance: float = 0.07

## Pixel size of each tile on screen — source PNG 32px, use integer multiples (32, 64, 128…)
@export var tile_size: int = 128
## Scale of large biome patches (smaller value = larger patches)
@export var terrain_frequency: float = 0.025
@export var terrain_seed: int = 7
## Small color variation noise
@export var detail_frequency: float = 0.18
## Overall brightness (0=black, 1=fully original)
@export var brightness: float = 0.82
@export var viewport_margin_tiles: int = 4

## Hazard system settings
## The world is divided into cells of hazard_cell_tiles×hazard_cell_tiles tiles each.
## Each cell can be a hazard object — large, single piece, like an object on the ground.
@export var hazard_cell_tiles: int = 7
## How many tiles each hazard patch covers (3=384px, 4=512px, 5=640px)
@export var hazard_patch_tiles: int = 4
## Noise values above this threshold trigger a hazard in that cell
@export var hazard_threshold: float = 0.35
@export var hazard_seed: int = 42
## Decorative overlay chance per hazard (0=never, 1=always)
@export var hazard_decor_chance: float = 0.70

# ── Color palette — natural, low saturation ───────────────────────────────────
const _GROUP_A_COLORS: Array[Color] = [  # organic terrain (forest/dirt/soil)
	Color(0.42, 0.38, 0.28, 1.0),
	Color(0.36, 0.32, 0.23, 1.0),
	Color(0.48, 0.43, 0.31, 1.0),
]
const _GROUP_B_COLORS: Array[Color] = [  # stone/metal terrain (stone/metal/concrete)
	Color(0.35, 0.35, 0.38, 1.0),
	Color(0.28, 0.28, 0.32, 1.0),
	Color(0.40, 0.40, 0.44, 1.0),
]

# ── Hazard color palettes ──────────────────────────────────────────────
const _HAZARD_LAVA_COLORS: Array[Color] = [  # molten lava — red/orange
	Color(0.82, 0.18, 0.03, 1.0),
	Color(0.95, 0.38, 0.05, 1.0),
	Color(0.68, 0.12, 0.02, 1.0),
]
const _HAZARD_WATER_COLORS: Array[Color] = [  # deep water / swamp — dark blue
	Color(0.10, 0.28, 0.65, 1.0),
	Color(0.07, 0.20, 0.50, 1.0),
	Color(0.15, 0.38, 0.72, 1.0),
]
const _HAZARD_RADIO_COLORS: Array[Color] = [  # radioactive — neon green
	Color(0.15, 0.62, 0.12, 1.0),
	Color(0.08, 0.45, 0.08, 1.0),
	Color(0.22, 0.75, 0.18, 1.0),
]

# 2D noise: which region is group A/B
var _terrain_noise: FastNoiseLite = FastNoiseLite.new()
# 2D noise: color variant (between 3 colors)
var _detail_noise: FastNoiseLite = FastNoiseLite.new()
# 2D noise: which tile variant (between 6 tiles)
var _variant_noise: FastNoiseLite = FastNoiseLite.new()

## Group A tiles (flat_tile_0..5 = old, flat_new_0..5 = new organic)
var _tiles_a: Array[Texture2D] = []
## Group B tiles (flat_tile_... = old stone/metal, flat_new_6..11 = new)
var _tiles_b: Array[Texture2D] = []

# ── Hazard noise ─────────────────────────────────────────────────────────────
# Presence: above threshold → this tile is a hazard zone
var _hazard_presence_noise: FastNoiseLite = FastNoiseLite.new()
# Type: lava / water / radiation differentiation (large patches)
var _hazard_type_noise: FastNoiseLite = FastNoiseLite.new()
# Variant: which tile variant to select
var _hazard_variant_noise: FastNoiseLite = FastNoiseLite.new()

## Lav, su, radyasyon tile setleri (her biri 4 varyant)
var _tiles_lava: Array[Texture2D] = []
var _tiles_water: Array[Texture2D] = []
var _tiles_radio: Array[Texture2D] = []

## Decorative overlay sprites (drawn on top of hazard tiles)
var _decor_lava: Texture2D = null
var _decor_water: Texture2D = null
var _decor_radio: Texture2D = null

## 17 adet hex tile havuzu (tile_backgrounds/tile_1..17.png)
var _hex_tiles: Array[Texture2D] = []
## Large overlay tiles
var _bigtile1: Texture2D = null
var _bigtile2: Texture2D = null


func _ready() -> void:
	# Pixel-perfect drawing — completely prevents edge bleeding
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group("background_tiler")

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

	# ── Hazard noise initialization — sampled at cell coordinates ───────
	_hazard_presence_noise.seed = hazard_seed
	_hazard_presence_noise.frequency = 0.15   # ~6-7 cell-spaced clusters
	_hazard_presence_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_hazard_presence_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_hazard_presence_noise.fractal_octaves = 3

	_hazard_type_noise.seed = hazard_seed + 13
	_hazard_type_noise.frequency = 0.08   # large lava/water/radiation zones
	_hazard_type_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_hazard_type_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_hazard_type_noise.fractal_octaves = 2

	_hazard_variant_noise.seed = hazard_seed + 67
	_hazard_variant_noise.frequency = 1.2   # high variation per cell
	_hazard_variant_noise.noise_type = FastNoiseLite.TYPE_VALUE

	# Group A: organic — old flat_tile_0..2 + new flat_new_0..5
	for i in [0, 1, 2]:
		var t: Texture2D = _try_load("res://assets/backgrounds/flat_tile_%d.png" % i)
		if t:
			_tiles_a.append(t)
	for i in range(6):
		var t: Texture2D = _try_load("res://assets/backgrounds/flat_new_%d.png" % i)
		if t:
			_tiles_a.append(t)

	# Group B: stone/metal — old flat_tile_3..5 + new flat_new_6..11
	for i in [3, 4, 5]:
		var t: Texture2D = _try_load("res://assets/backgrounds/flat_tile_%d.png" % i)
		if t:
			_tiles_b.append(t)
	for i in range(6, 12):
		var t: Texture2D = _try_load("res://assets/backgrounds/flat_new_%d.png" % i)
		if t:
			_tiles_b.append(t)

	# Fallback: if nothing loaded, show placeholder warning
	if _tiles_a.is_empty() and _tiles_b.is_empty():
		push_warning("BackgroundTiler: no tiles could be loaded!")

	# Load hex tiles
	for i in range(1, 18):
		var t: Texture2D = _try_load("res://assets/tile_backgrounds/tile_%d.png" % i)
		if t:
			_hex_tiles.append(t)
	if use_hex_tiles and _hex_tiles.is_empty():
		push_warning("BackgroundTiler: hex tiles not found — check tile_backgrounds/ folder")

	# Load bigtiles
	_bigtile1 = _try_load("res://assets/tile_backgrounds/bigtile1.png")
	_bigtile2 = _try_load("res://assets/tile_backgrounds/bigtile2.png")

	# ── Load hazard tiles ───────────────────────────────────────────────────────
	for i in range(4):
		var t: Texture2D = _try_load("res://assets/backgrounds/hazards/lava_%d.png" % i)
		if t:
			_tiles_lava.append(t)
	for i in range(4):
		var t: Texture2D = _try_load("res://assets/backgrounds/hazards/water_%d.png" % i)
		if t:
			_tiles_water.append(t)
	for i in range(4):
		var t: Texture2D = _try_load("res://assets/backgrounds/hazards/radio_%d.png" % i)
		if t:
			_tiles_radio.append(t)

	# Load decorative overlay sprites (optional)
	_decor_lava  = _try_load("res://assets/backgrounds/hazards/decor_lava.png")
	_decor_water = _try_load("res://assets/backgrounds/hazards/decor_water.png")
	_decor_radio = _try_load("res://assets/backgrounds/hazards/decor_radio.png")


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

	# ── Hex tile mode: simple random grid, no biome/hazard ────────────────────────
	if use_hex_tiles:
		_draw_hex_tiles(cam, vp_size)
		return
	var ts: float = float(tile_size)
	# Snap camera position to full pixel for grid calculation
	var cam_pos: Vector2 = cam.global_position.round()

	var min_tx: int = int(floor((cam_pos.x - vp_size.x * 0.5) / ts)) - viewport_margin_tiles
	var max_tx: int = int(ceil( (cam_pos.x + vp_size.x * 0.5) / ts)) + viewport_margin_tiles
	var min_ty: int = int(floor((cam_pos.y - vp_size.y * 0.5) / ts)) - viewport_margin_tiles
	var max_ty: int = int(ceil( (cam_pos.y + vp_size.y * 0.5) / ts)) + viewport_margin_tiles

	# cam_frac = camera's difference from round() (-0.5..0.5)
	# draw_set_transform(cam_frac) → tiles always land on exact integer screen pixels
	# Proof: screen_x = tx*ts + cam_frac - cam.x + vp/2
	#             = tx*ts + (cam.x - round(cam.x)) - cam.x + vp/2
	#             = tx*ts - round(cam.x) + vp/2  ← all terms integer ✓
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

			# Deterministic tile + color variant
			var vn: float = _variant_noise.get_noise_2d(float(tx), float(ty))
			var vi: int = int(abs(vn) * float(pool.size() - 1) + 0.5) % pool.size()
			var tex: Texture2D = pool[vi]

			var dn: float = _detail_noise.get_noise_2d(float(tx), float(ty))
			var ci: int = int(abs(dn) * 2.9)
			var palette: Array[Color] = _GROUP_B_COLORS if is_b else _GROUP_A_COLORS
			var base: Color = palette[ci]
			var color: Color = Color(base.r * brightness, base.g * brightness, base.b * brightness, 1.0)

			# 2px symmetric overlap: each tile overlaps 2px over its neighbor on all 4 sides
			# → GPU rasterization gaps fully closed, invisible on seamless tiles
			const PAD: float = 2.0
			var pos: Vector2 = Vector2(tx * ts - PAD, ty * ts - PAD)
			var dst: Rect2 = Rect2(pos, Vector2(ts + PAD * 2.0, ts + PAD * 2.0))
			draw_texture_rect(tex, dst, false, color)

	# ── Second pass: Hazard objects — organic blob (large center, small/scattered edges) ──
	# Each hazard cell: one large center piece + small scattered noise-gated tiles on the perimeter.
	# Boundaries are irregular.
	var cws: float = float(hazard_cell_tiles) * ts
	var min_hcx: int = int(floor((cam_pos.x - vp_size.x * 0.5) / cws)) - 1
	var max_hcx: int = int(ceil( (cam_pos.x + vp_size.x * 0.5) / cws)) + 1
	var min_hcy: int = int(floor((cam_pos.y - vp_size.y * 0.5) / cws)) - 1
	var max_hcy: int = int(ceil( (cam_pos.y + vp_size.y * 0.5) / cws)) + 1

	for hcy in range(min_hcy, max_hcy + 1):
		for hcx in range(min_hcx, max_hcx + 1):
			if not _cell_has_hazard(hcx, hcy):
				continue

			var htype: int = _get_hazard_type(hcx, hcy)
			var h_pool: Array[Texture2D]
			var h_palette: Array[Color]
			match htype:
				0:
					h_pool = _tiles_lava
					h_palette = _HAZARD_LAVA_COLORS
				1:
					h_pool = _tiles_water
					h_palette = _HAZARD_WATER_COLORS
				_:
					h_pool = _tiles_radio
					h_palette = _HAZARD_RADIO_COLORS

			var ccx: float = (float(hcx) + 0.5) * cws
			var ccy: float = (float(hcy) + 0.5) * cws

			var h_ci: int = clampi(int(abs(_detail_noise.get_noise_2d(float(hcx) * 19.7, float(hcy) * 19.7)) * 2.9), 0, 2)
			var h_base: Color = h_palette[h_ci]
			var h_color: Color = Color(h_base.r * brightness, h_base.g * brightness, h_base.b * brightness, 1.0)

			# ── Center piece: large square, tiled seamlessly ───────────────────
			var center_size: float = ts * 2.2
			var c_rect: Rect2 = Rect2(
				Vector2(ccx - center_size * 0.5, ccy - center_size * 0.5),
				Vector2(center_size, center_size)
			)
			if h_pool.is_empty():
				draw_rect(c_rect, h_color)
			else:
				var h_vi_c: int = int(abs(_hazard_variant_noise.get_noise_2d(float(hcx), float(hcy))) * float(h_pool.size() - 1) + 0.5) % h_pool.size()
				draw_texture_rect(h_pool[h_vi_c], c_rect, true, h_color)

			# ── Perimeter tiles: noise-gated, small, laterally offset ───────────────
			# hg: radius in tiles, total grid is 2hg+1 x 2hg+1

			# Decorative overlay — one per cell, 3× scaled (64px → 192px)
			var h_dv: float = _hazard_variant_noise.get_noise_2d(float(hcx) + 333.0, float(hcy) + 333.0)
			if abs(h_dv) <= hazard_decor_chance:
				var decor_tex: Texture2D
				match htype:
					0: decor_tex = _decor_lava
					1: decor_tex = _decor_water
					_: decor_tex = _decor_radio
				if decor_tex != null:
					var dscale: float = 3.0
					var dw: float = float(decor_tex.get_width())  * dscale
					var dh: float = float(decor_tex.get_height()) * dscale
					var ddst: Rect2 = Rect2(
						Vector2(ccx - dw * 0.5, ccy - dh * 0.5),
						Vector2(dw, dh)
					)
					draw_texture_rect(decor_tex, ddst, false, Color(1.0, 1.0, 1.0, 0.92))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## ── Hazard query – public API ──────────────────────────────────────────

func _cell_has_hazard(hcx: int, hcy: int) -> bool:
	return _hazard_presence_noise.get_noise_2d(float(hcx), float(hcy)) > hazard_threshold


func _get_hazard_type(hcx: int, hcy: int) -> int:
	var tv: float = _hazard_type_noise.get_noise_2d(float(hcx), float(hcy))
	if tv < -0.333:
		return 0  # lav
	elif tv < 0.333:
		return 1  # su
	return 2      # radyasyon


## Is there a hazard in the given cell? (used by HazardCollider)
func is_hazard_cell(hcx: int, hcy: int) -> bool:
	return _cell_has_hazard(hcx, hcy)


## Is a world coordinate inside a hazard patch area?
## Called by enemy spawn and Sonic Jump checks.
func is_hazard_at_world(world_pos: Vector2) -> bool:
	var cws: float = float(hazard_cell_tiles) * float(tile_size)
	var pws: float = float(hazard_patch_tiles) * float(tile_size)
	var hcx: int = int(floor(world_pos.x / cws))
	var hcy: int = int(floor(world_pos.y / cws))
	if not _cell_has_hazard(hcx, hcy):
		return false
	var ccx: float = (float(hcx) + 0.5) * cws
	var ccy: float = (float(hcy) + 0.5) * cws
	var half_p: float = pws * 0.5
	return abs(world_pos.x - ccx) <= half_p and abs(world_pos.y - ccy) <= half_p


## ── Hex tile grid drawing ──────────────────────────────────────────────────────────
## Ground is fully covered with bigtile1.
## Deterministic hash roll: 7% chance to use bigtile2.
func _draw_hex_tiles(cam: Camera2D, vp_size: Vector2) -> void:
	if _bigtile1 == null:
		return

	var tw: float = float(_bigtile1.get_width())  * 0.70
	var th: float = float(_bigtile1.get_height()) * 0.70
	var cam_pos: Vector2 = cam.global_position.round()
	var cam_frac: Vector2 = cam.global_position - cam_pos
	draw_set_transform(cam_frac, 0.0, Vector2.ONE)

	var min_tx: int = int(floor((cam_pos.x - vp_size.x * 0.5) / tw)) - viewport_margin_tiles
	var max_tx: int = int(ceil( (cam_pos.x + vp_size.x * 0.5) / tw)) + viewport_margin_tiles
	var min_ty: int = int(floor((cam_pos.y - vp_size.y * 0.5) / th)) - viewport_margin_tiles
	var max_ty: int = int(ceil( (cam_pos.y + vp_size.y * 0.5) / th)) + viewport_margin_tiles

	var t2: int = int(bigtile2_chance * 10000.0)
	var col: Color = Color(hex_brightness, hex_brightness, hex_brightness, 1.0)

	for ty in range(min_ty, max_ty + 1):
		for tx in range(min_tx, max_tx + 1):
			var h: int = ((tx * 73856093) ^ (ty * 19349663) ^ hex_random_seed) & 0x7FFFFFFF
			h = ((h >> 16) ^ h) & 0x7FFFFFFF

			var tex: Texture2D
			if (h % 10000) < t2 and _bigtile2 != null:
				tex = _bigtile2
			else:
				tex = _bigtile1

			const PAD: float = 1.0
			var pos: Vector2 = Vector2(tx * tw - PAD, ty * th - PAD)
			draw_texture_rect(tex, Rect2(pos, Vector2(tw + PAD * 2.0, th + PAD * 2.0)), false, col)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
