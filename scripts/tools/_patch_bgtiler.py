"""
background_tiler.gd patch:
- simplify the hex tile export block (remove bigtile_cell_size, bigtile1_chance, bigtile_alpha, hex_tile_size)
- hex_brightness defaultunu 0.68 yap
- _draw_hex_tiles fonksiyonunu yeniden yaz: sadece bigtile1/bigtile2
"""
import re

PATH = "/Users/berkay/Desktop/work/geni-hero/scripts/world/background_tiler.gd"

with open(PATH, "r", encoding="utf-8") as f:
    src = f.read()

# ── 1. Export block: replace with new (simplified) version ─────────────────────
OLD_EXPORTS = re.compile(
    r'## .{0,10} Hex tile arka plan modu .+?@export var bigtile_alpha: float = 1\.0',
    re.DOTALL
)

NEW_EXPORTS = (
    "## \u2500\u2500 Hex tile arka plan modu \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n"
    "## true iken yaln\u0131zca bigtile1.png / bigtile2.png kullan\u0131l\u0131r.\n"
    "@export var use_hex_tiles: bool = false\n"
    "## Hash seed \u2014 de\u011fi\u015ftirince farkl\u0131 d\u00fczlem d\u00fczeni\n"
    "@export var hex_random_seed: int = 12345\n"
    "## Parlakl\u0131k \u00e7arpan\u0131 (1.0 = orijinal, d\u00fc\u015f\u00fcr\u00fcnce karar\u0131r)\n"
    "@export var hex_brightness: float = 0.68\n"
    "## bigtile2 g\u00f6r\u00fcnme olas\u0131l\u0131\u011f\u0131 (0.0\u20131.0) \u2014 nadir\n"
    "@export var bigtile2_chance: float = 0.07"
)

src_new, n = OLD_EXPORTS.subn(NEW_EXPORTS, src, count=1)
assert n == 1, "Export block not found!"

# ── 2. _draw_hex_tiles fonksiyonu: yeniden yaz ──────────────────────────────
OLD_FN = re.compile(
    r'## .{0,10} Hex tile .zgara .izimi .+?draw_set_transform\(Vector2\.ZERO, 0\.0, Vector2\.ONE\)',
    re.DOTALL
)

NEW_FN = (
    "## \u2500\u2500 Hex tile \u0131zgara \u00e7izimi \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n"
    "## Zemin tamam\u0131 bigtile1 ile kapat\u0131l\u0131r.\n"
    "## Deterministik hash roll: %7 ihtimalde bigtile2 kullan\u0131l\u0131r.\n"
    "func _draw_hex_tiles(cam: Camera2D, vp_size: Vector2) -> void:\n"
    "\tif _bigtile1 == null:\n"
    "\t\treturn\n"
    "\n"
    "\tvar tw: float = float(_bigtile1.get_width())\n"
    "\tvar th: float = float(_bigtile1.get_height())\n"
    "\tvar cam_pos: Vector2 = cam.global_position.round()\n"
    "\tvar cam_frac: Vector2 = cam.global_position - cam_pos\n"
    "\tdraw_set_transform(cam_frac, 0.0, Vector2.ONE)\n"
    "\n"
    "\tvar min_tx: int = int(floor((cam_pos.x - vp_size.x * 0.5) / tw)) - viewport_margin_tiles\n"
    "\tvar max_tx: int = int(ceil( (cam_pos.x + vp_size.x * 0.5) / tw)) + viewport_margin_tiles\n"
    "\tvar min_ty: int = int(floor((cam_pos.y - vp_size.y * 0.5) / th)) - viewport_margin_tiles\n"
    "\tvar max_ty: int = int(ceil( (cam_pos.y + vp_size.y * 0.5) / th)) + viewport_margin_tiles\n"
    "\n"
    "\tvar t2: int = int(bigtile2_chance * 10000.0)\n"
    "\tvar col: Color = Color(hex_brightness, hex_brightness, hex_brightness, 1.0)\n"
    "\n"
    "\tfor ty in range(min_ty, max_ty + 1):\n"
    "\t\tfor tx in range(min_tx, max_tx + 1):\n"
    "\t\t\tvar h: int = ((tx * 73856093) ^ (ty * 19349663) ^ hex_random_seed) & 0x7FFFFFFF\n"
    "\t\t\th = ((h >> 16) ^ h) & 0x7FFFFFFF\n"
    "\n"
    "\t\t\tvar tex: Texture2D\n"
    "\t\t\tif (h % 10000) < t2 and _bigtile2 != null:\n"
    "\t\t\t\ttex = _bigtile2\n"
    "\t\t\telse:\n"
    "\t\t\t\ttex = _bigtile1\n"
    "\n"
    "\t\t\tconst PAD: float = 1.0\n"
    "\t\t\tvar pos: Vector2 = Vector2(tx * tw - PAD, ty * th - PAD)\n"
    "\t\t\tdraw_texture_rect(tex, Rect2(pos, Vector2(tw + PAD * 2.0, th + PAD * 2.0)), false, col)\n"
    "\n"
    "\tdraw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)"
)

src_new2, n2 = OLD_FN.subn(NEW_FN, src_new, count=1)
assert n2 == 1, "Function block not found!"

with open(PATH, "w", encoding="utf-8") as f:
    f.write(src_new2)

print("Patch OK — export block and _draw_hex_tiles updated.")
