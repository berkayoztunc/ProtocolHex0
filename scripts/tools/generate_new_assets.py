#!/usr/bin/env python3
"""
Generate placeholder PNGs + .import files for the 22 new weapon/VFX/icon assets.

Groups:
  A  - 4 projectile sprites  (assets/weapons/)
  B  - 10 VFX effects        (assets/vfx/)
  C  - 7 weapon icons        (assets/ui/icons/)
  D  - 1 world bomb sprite   (assets/vfx/)
"""
import hashlib
import math
import os
import random
import uuid
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]

# ── helpers ─────────────────────────────────────────────────────────────────

def ensure(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def save(img: Image.Image, path: Path) -> None:
    ensure(path)
    img.save(path)
    print(f"  GEN  {path.relative_to(ROOT)}")


def canvas(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def make_import(png_path: Path) -> None:
    """Write a Godot 4 .import file next to the PNG."""
    rel = png_path.relative_to(ROOT).as_posix()
    uid = hashlib.md5(str(png_path).encode()).hexdigest()[:14]
    basename = png_path.name
    md5 = hashlib.md5(rel.encode()).hexdigest()[:8]
    content = f"""[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://{uid}"
path="res://.godot/imported/{basename}-{md5}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://{rel}"
dest_files=["res://.godot/imported/{basename}-{md5}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""
    import_path = Path(str(png_path) + ".import")
    with open(import_path, "w") as f:
        f.write(content)
    print(f"  IMP  {import_path.relative_to(ROOT)}")


def gen(img: Image.Image, path: Path) -> None:
    save(img, path)
    make_import(path)


# ── GRUP A – Projectile sprites ─────────────────────────────────────────────

def proj_rocket_blaster() -> None:
    """32×32 top-down rocket: dark metal body, red tip, orange flame trail."""
    img = canvas(32, 32)
    d = ImageDraw.Draw(img)
    # flame trail (behind)
    for i, (a, r) in enumerate([(60, 10), (110, 8), (160, 6)]):
        d.ellipse((2 - i, 14 + i, 14 - i, 18 - i), fill=(255, 130 + i * 20, 30, a))
    # body
    d.polygon([(8, 12), (26, 14), (30, 16), (26, 18), (8, 20)],
              fill=(180, 50, 40, 255), outline=(20, 10, 10, 255))
    # nose cone
    d.polygon([(26, 13), (32, 16), (26, 19)], fill=(220, 220, 220, 255))
    # fin left
    d.polygon([(8, 12), (4, 8), (12, 14)], fill=(130, 30, 30, 255))
    # fin right
    d.polygon([(8, 20), (4, 24), (12, 18)], fill=(130, 30, 30, 255))
    gen(img, ROOT / "assets/weapons/proj_rocket_blaster.png")


def proj_octo_gun() -> None:
    """24×12 small kinetic bullet: copper oval, bright copper tip."""
    img = canvas(24, 12)
    d = ImageDraw.Draw(img)
    # glow
    d.ellipse((0, 1, 22, 11), fill=(255, 160, 60, 60))
    # body
    d.ellipse((3, 2, 20, 10), fill=(200, 120, 50, 255), outline=(80, 40, 10, 255))
    # highlight
    d.ellipse((5, 3, 10, 6), fill=(255, 200, 120, 180))
    # tip
    d.polygon([(20, 5), (24, 6), (20, 7)], fill=(240, 200, 100, 255))
    gen(img, ROOT / "assets/weapons/proj_octo_gun.png")


def proj_blitz_bomb() -> None:
    """32×32 cryo bomb: icy blue sphere with crystal shimmer."""
    img = canvas(32, 32)
    d = ImageDraw.Draw(img)
    cx, cy = 16, 16
    # outer cryo glow rings
    for r, a in [(14, 40), (11, 80), (9, 140)]:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(140, 230, 255, a))
    # sphere body
    d.ellipse((cx - 9, cy - 9, cx + 9, cy + 9),
              fill=(60, 180, 240, 255), outline=(20, 100, 180, 255), width=2)
    # ice highlight
    d.ellipse((cx - 6, cy - 6, cx - 2, cy - 2), fill=(220, 245, 255, 200))
    # crystal spikes
    for angle in range(0, 360, 60):
        rx = cx + int(11 * math.cos(math.radians(angle)))
        ry = cy + int(11 * math.sin(math.radians(angle)))
        rx2 = cx + int(8 * math.cos(math.radians(angle + 15)))
        ry2 = cy + int(8 * math.sin(math.radians(angle + 15)))
        d.line((cx, cy, rx, ry), fill=(200, 240, 255, 180), width=1)
        d.polygon([(rx, ry), (rx2, ry2), (cx, cy)],
                  fill=(180, 230, 255, 120))
    gen(img, ROOT / "assets/weapons/proj_blitz_bomb.png")


def proj_orbital_mayhem() -> None:
    """28×32 rocket falling at 45°: dark metal, fire+smoke trailing top-left."""
    img = canvas(28, 32)
    d = ImageDraw.Draw(img)
    # smoke trail (top-left)
    for i, (x, y, r, a) in enumerate([(3, 4, 6, 50), (5, 8, 5, 80), (6, 12, 4, 100)]):
        d.ellipse((x - r, y - r, x + r, y + r), fill=(140, 120, 100, a))
    # fire trail
    for i, (x, y, r, a) in enumerate([(8, 10, 5, 120), (10, 14, 4, 160)]):
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 140, 40, a))
    # body (rotated ~45 degrees)
    body = [(8, 28), (12, 24), (22, 10), (26, 8), (28, 12), (18, 26), (14, 30)]
    d.polygon(body, fill=(100, 110, 130, 255), outline=(20, 20, 30, 255))
    # nose tip
    d.polygon([(26, 8), (28, 4), (28, 12)], fill=(200, 210, 220, 255))
    # fin
    d.polygon([(8, 28), (4, 30), (12, 24)], fill=(70, 80, 100, 255))
    gen(img, ROOT / "assets/weapons/proj_orbital_mayhem.png")


# ── GRUP B – VFX ─────────────────────────────────────────────────────────────

def vfx_explosion_burst() -> None:
    """96×96 explosion ring: orange-red multi-layer burst, transparent center."""
    img = canvas(96, 96)
    d = ImageDraw.Draw(img)
    cx = 48
    # outer heat shimmer
    for r, col, a in [
        (44, (255, 180, 60), 40),
        (38, (255, 130, 30), 90),
        (32, (255, 80, 20), 140),
        (24, (255, 200, 80), 170),
        (18, (255, 255, 200), 80),
    ]:
        d.ellipse((cx - r, cx - r, cx + r, cx + r),
                  outline=(col[0], col[1], col[2], a), width=5)
    # debris flecks
    random.seed(42)
    for _ in range(16):
        angle = random.uniform(0, math.tau)
        dist = random.uniform(20, 42)
        x = cx + int(dist * math.cos(angle))
        y = cx + int(dist * math.sin(angle))
        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(255, 200, 100, 180))
    gen(img, ROOT / "assets/vfx/vfx_explosion_burst.png")


def vfx_electric_arc() -> None:
    """64×64 electric arc: jagged blue-white lightning from center outward."""
    img = canvas(64, 64)
    d = ImageDraw.Draw(img)
    cx, cy = 32, 32
    random.seed(7)
    # 6 branches
    for angle_deg in range(0, 360, 60):
        pts = [(cx, cy)]
        x, y = cx, cy
        for seg in range(4):
            dist = random.uniform(6, 10)
            jitter = random.uniform(-8, 8)
            angle = math.radians(angle_deg) + math.radians(jitter)
            x += int(dist * math.cos(angle))
            y += int(dist * math.sin(angle))
            pts.append((x, y))
        for i in range(len(pts) - 1):
            a = int(255 * (1 - i / len(pts)))
            d.line([pts[i], pts[i + 1]], fill=(160, 220, 255, a), width=3)
            d.line([pts[i], pts[i + 1]], fill=(240, 250, 255, a // 2), width=1)
    # bright center
    d.ellipse((29, 29, 35, 35), fill=(255, 255, 255, 230))
    gen(img, ROOT / "assets/vfx/vfx_electric_arc.png")


def vfx_sonic_jump_flash() -> None:
    """80×80 sonic jump origin: cyan-white radial starburst."""
    img = canvas(80, 80)
    d = ImageDraw.Draw(img)
    cx, cy = 40, 40
    # glow core
    for r, a in [(20, 30), (14, 70), (8, 140), (5, 220)]:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(180, 255, 255, a))
    # radial streaks
    for angle_deg in range(0, 360, 22):
        angle = math.radians(angle_deg)
        inner = 8
        outer = random.randint(22, 36)
        x0 = cx + int(inner * math.cos(angle))
        y0 = cy + int(inner * math.sin(angle))
        x1 = cx + int(outer * math.cos(angle))
        y1 = cy + int(outer * math.sin(angle))
        a = random.randint(140, 240)
        d.line([(x0, y0), (x1, y1)], fill=(120, 240, 255, a), width=2)
    # white center dot
    d.ellipse((37, 37, 43, 43), fill=(255, 255, 255, 255))
    gen(img, ROOT / "assets/vfx/vfx_sonic_jump_flash.png")


def vfx_sonic_jump_ring() -> None:
    """96×96 sonic jump landing AoE: hollow cyan shockwave ring."""
    img = canvas(96, 96)
    d = ImageDraw.Draw(img)
    cx = 48
    for r, width, a in [(40, 6, 200), (34, 4, 140), (28, 2, 80)]:
        d.ellipse((cx - r, cx - r, cx + r, cx + r),
                  outline=(80, 230, 255, a), width=width)
    # outward energy spikes
    for angle_deg in range(0, 360, 30):
        angle = math.radians(angle_deg)
        x0 = cx + int(38 * math.cos(angle))
        y0 = cx + int(38 * math.sin(angle))
        x1 = cx + int(46 * math.cos(angle))
        y1 = cx + int(46 * math.sin(angle))
        d.line([(x0, y0), (x1, y1)], fill=(180, 255, 255, 160), width=2)
    gen(img, ROOT / "assets/vfx/vfx_sonic_jump_ring.png")


def vfx_spin_laser_beam() -> None:
    """256×8 spin laser beam: green neon horizontal bar, bright core."""
    img = canvas(256, 8)
    d = ImageDraw.Draw(img)
    # outer soft glow rows
    for y, a in [(0, 30), (1, 80), (2, 150)]:
        d.line([(0, y), (255, y)], fill=(80, 255, 100, a))
        d.line([(0, 7 - y), (255, 7 - y)], fill=(80, 255, 100, a))
    # bright core
    d.line([(0, 3), (255, 3)], fill=(220, 255, 220, 255))
    d.line([(0, 4), (255, 4)], fill=(220, 255, 220, 255))
    gen(img, ROOT / "assets/vfx/vfx_spin_laser_beam.png")


def vfx_freeze_burst() -> None:
    """96×96 cryo AoE freeze: cyan-white ice crystal ring."""
    img = canvas(96, 96)
    d = ImageDraw.Draw(img)
    cx = 48
    for r, a in [(42, 60), (36, 110), (28, 160)]:
        d.ellipse((cx - r, cx - r, cx + r, cx + r),
                  outline=(140, 230, 255, a), width=4)
    # ice shards
    for angle_deg in range(0, 360, 30):
        angle = math.radians(angle_deg)
        x0 = cx + int(28 * math.cos(angle))
        y0 = cx + int(28 * math.sin(angle))
        x1 = cx + int(44 * math.cos(angle))
        y1 = cx + int(44 * math.sin(angle))
        ox = int(5 * math.cos(angle + math.pi / 2))
        oy = int(5 * math.sin(angle + math.pi / 2))
        d.polygon([(x0, y0), (x0 + ox, y0 + oy), (x1, y1), (x0 - ox, y0 - oy)],
                  fill=(200, 245, 255, 160))
    gen(img, ROOT / "assets/vfx/vfx_freeze_burst.png")


def vfx_magnetic_pulse() -> None:
    """128×128 magnetic field activation: blue-teal concentric field rings."""
    img = canvas(128, 128)
    d = ImageDraw.Draw(img)
    cx = 64
    for r, a in [(58, 50), (48, 90), (36, 130), (24, 160), (12, 180)]:
        d.ellipse((cx - r, cx - r, cx + r, cx + r),
                  outline=(60, 200, 220, a), width=3)
    # horizontal field lines (top + bottom halves)
    for y_off in range(-50, 55, 10):
        xl = cx - int(math.sqrt(max(0, 58 * 58 - y_off * y_off))) + 2
        xr = cx + int(math.sqrt(max(0, 58 * 58 - y_off * y_off))) - 2
        if xl < xr:
            a = int(80 * (1 - abs(y_off) / 60))
            d.line([(xl, cx + y_off), (xr, cx + y_off)],
                   fill=(90, 210, 230, max(0, a)), width=1)
    # center glow
    for r, a in [(8, 80), (5, 160), (3, 230)]:
        d.ellipse((cx - r, cx - r, cx + r, cx + r), fill=(120, 240, 255, a))
    gen(img, ROOT / "assets/vfx/vfx_magnetic_pulse.png")


def vfx_rocket_smoke_trail() -> None:
    """48×48 rocket smoke puff: soft grey-brown cloud."""
    img = canvas(48, 48)
    d = ImageDraw.Draw(img)
    random.seed(99)
    for _ in range(6):
        cx = random.randint(14, 34)
        cy = random.randint(14, 34)
        r = random.randint(6, 12)
        a = random.randint(60, 130)
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(140, 130, 120, a))
    gen(img, ROOT / "assets/vfx/vfx_rocket_smoke_trail.png")


def vfx_orbital_streak() -> None:
    """64×64 orbital mayhem falling streak: orange fire to grey smoke diagonal."""
    img = canvas(64, 64)
    d = ImageDraw.Draw(img)
    # smoke top-left
    for i, (x, y, r, a) in enumerate([
        (8, 8, 8, 70), (12, 14, 7, 100), (16, 20, 6, 120)
    ]):
        d.ellipse((x - r, y - r, x + r, y + r), fill=(140, 130, 120, a))
    # fire streak diagonal
    pts = [(20, 24), (24, 20), (48, 44), (44, 48)]
    d.polygon(pts, fill=(255, 140, 40, 200))
    pts2 = [(22, 22), (25, 21), (46, 46), (43, 47)]
    d.polygon(pts2, fill=(255, 220, 100, 140))
    # tip glow
    d.ellipse((46, 46, 54, 54), fill=(255, 180, 60, 180))
    gen(img, ROOT / "assets/vfx/vfx_orbital_streak.png")


def vfx_world_bomb_indicator() -> None:
    """96×96 world bomb warning ring: pulsing red danger indicator."""
    img = canvas(96, 96)
    d = ImageDraw.Draw(img)
    cx = 48
    for r, width, a in [(44, 7, 220), (38, 4, 140), (32, 2, 80)]:
        d.ellipse((cx - r, cx - r, cx + r, cx + r),
                  outline=(220, 40, 40, a), width=width)
    # danger ticks around ring
    for angle_deg in range(0, 360, 45):
        angle = math.radians(angle_deg)
        x0 = cx + int(36 * math.cos(angle))
        y0 = cx + int(36 * math.sin(angle))
        x1 = cx + int(44 * math.cos(angle))
        y1 = cx + int(44 * math.sin(angle))
        d.line([(x0, y0), (x1, y1)], fill=(255, 80, 80, 200), width=3)
    # inner cross
    d.line([(48, 30), (48, 44)], fill=(220, 40, 40, 180), width=3)
    d.ellipse((44, 46, 52, 54), fill=(220, 40, 40, 180))
    gen(img, ROOT / "assets/vfx/vfx_world_bomb_indicator.png")


# ── GRUP C – Weapon Icons ────────────────────────────────────────────────────

def _icon_base(size: int = 64) -> tuple:
    img = canvas(size, size)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((3, 3, size - 4, size - 4), radius=10,
                         fill=(28, 38, 55, 230), outline=(100, 140, 200, 255), width=2)
    return img, d


def icon_rocket_blaster() -> None:
    img, d = _icon_base()
    # rocket body
    d.polygon([(14, 32), (40, 22), (52, 32), (40, 42)],
              fill=(200, 60, 50, 255), outline=(20, 10, 10, 255))
    d.polygon([(40, 22), (52, 32), (56, 28)], fill=(220, 220, 220, 255))
    # flame
    d.ellipse((8, 28, 20, 36), fill=(255, 140, 40, 200))
    d.ellipse((6, 30, 14, 34), fill=(255, 220, 100, 160))
    gen(img, ROOT / "assets/ui/icons/weapon_rocket_blaster.png")


def icon_octo_gun() -> None:
    img, d = _icon_base()
    # 6 barrels arranged in circle
    cx, cy = 32, 32
    for angle_deg in range(0, 360, 60):
        angle = math.radians(angle_deg)
        x0 = cx + int(8 * math.cos(angle))
        y0 = cy + int(8 * math.sin(angle))
        x1 = cx + int(22 * math.cos(angle))
        y1 = cy + int(22 * math.sin(angle))
        d.line([(x0, y0), (x1, y1)], fill=(160, 180, 200, 255), width=4)
        d.ellipse((x1 - 3, y1 - 3, x1 + 3, y1 + 3), fill=(200, 220, 255, 255))
    # center hub
    d.ellipse((26, 26, 38, 38), fill=(80, 110, 150, 255), outline=(160, 200, 240, 255), width=2)
    gen(img, ROOT / "assets/ui/icons/weapon_octo_gun.png")


def icon_sonic_jumper() -> None:
    img, d = _icon_base()
    # boot shape
    d.polygon([(22, 44), (22, 30), (28, 24), (40, 24), (40, 32), (34, 32), (34, 44)],
              fill=(80, 200, 240, 255), outline=(20, 80, 120, 255))
    # speed lines
    for i, y in enumerate([30, 35, 40]):
        d.line([(8, y), (20, y - i)], fill=(180, 240, 255, 200), width=2)
    # jump ring
    d.ellipse((16, 40, 48, 52), outline=(100, 220, 255, 180), width=3)
    gen(img, ROOT / "assets/ui/icons/weapon_sonic_jumper.png")


def icon_blitz_bomb() -> None:
    img, d = _icon_base()
    cx, cy = 32, 36
    # body
    d.ellipse((cx - 14, cy - 14, cx + 14, cy + 14),
              fill=(60, 160, 230, 255), outline=(20, 90, 160, 255), width=2)
    # ice highlight
    d.ellipse((cx - 8, cy - 10, cx - 2, cy - 4), fill=(200, 240, 255, 200))
    # fuse
    d.line([(cx, cy - 14), (cx + 6, cy - 22)], fill=(200, 180, 100, 255), width=3)
    d.ellipse((cx + 4, cy - 25, cx + 10, cy - 19), fill=(255, 220, 80, 220))
    # crystal shards
    for angle_deg in range(30, 360, 60):
        angle = math.radians(angle_deg)
        x1 = cx + int(16 * math.cos(angle))
        y1 = cy + int(16 * math.sin(angle))
        d.line([(cx, cy), (x1, y1)], fill=(180, 230, 255, 140), width=1)
    gen(img, ROOT / "assets/ui/icons/weapon_blitz_bomb.png")


def icon_spin_laser() -> None:
    img, d = _icon_base()
    cx, cy = 32, 32
    # outer emitter ring
    d.ellipse((cx - 20, cy - 20, cx + 20, cy + 20),
              outline=(80, 220, 100, 220), width=3)
    # laser beams (4 directions)
    for angle_deg in [0, 90, 180, 270]:
        angle = math.radians(angle_deg)
        x1 = cx + int(22 * math.cos(angle))
        y1 = cy + int(22 * math.sin(angle))
        x2 = cx + int(28 * math.cos(angle))
        y2 = cy + int(28 * math.sin(angle))
        d.line([(x1, y1), (x2, y2)], fill=(180, 255, 180, 220), width=3)
    # center core
    d.ellipse((cx - 6, cy - 6, cx + 6, cy + 6),
              fill=(120, 240, 120, 255), outline=(220, 255, 220, 255), width=2)
    # diagonal spin arcs
    for angle_deg in [30, 120, 210, 300]:
        angle = math.radians(angle_deg)
        x1 = cx + int(12 * math.cos(angle))
        y1 = cy + int(12 * math.sin(angle))
        x2 = cx + int(18 * math.cos(angle + 0.4))
        y2 = cy + int(18 * math.sin(angle + 0.4))
        d.line([(x1, y1), (x2, y2)], fill=(80, 255, 100, 180), width=2)
    gen(img, ROOT / "assets/ui/icons/weapon_spin_laser.png")


def icon_orbital_mayhem() -> None:
    img, d = _icon_base()
    # 3 rockets raining down at slight angles
    rockets = [
        [(20, 14), (18, 28), (24, 28), (22, 14)],
        [(30, 10), (27, 26), (33, 26), (31, 10)],
        [(40, 14), (38, 28), (44, 28), (42, 14)],
    ]
    for r in rockets:
        d.polygon(r, fill=(180, 50, 40, 255), outline=(20, 10, 10, 255))
        # tip
        tx = (r[0][0] + r[3][0]) // 2
        d.polygon([(r[0][0], r[0][1]), (r[3][0], r[3][1]), (tx, r[0][1] - 4)],
                  fill=(220, 220, 220, 255))
    # explosion at bottom
    for r, a in [(12, 80), (9, 140), (6, 200)]:
        d.ellipse((32 - r, 44 - r, 32 + r, 44 + r),
                  fill=(255, 150, 40, a))
    gen(img, ROOT / "assets/ui/icons/weapon_orbital_mayhem.png")


def icon_magnetic_field() -> None:
    img, d = _icon_base()
    cx, cy = 32, 36
    # horseshoe magnet
    d.arc((cx - 14, cy - 14, cx + 14, cy + 14), start=0, end=180,
          fill=(80, 200, 220, 255), width=8)
    d.rectangle((cx - 21, cy - 4, cx - 13, cy + 10), fill=(80, 200, 220, 255))
    d.rectangle((cx + 13, cy - 4, cx + 21, cy + 10), fill=(80, 200, 220, 255))
    # pole tips highlight
    d.rectangle((cx - 21, cy + 6, cx - 13, cy + 12), fill=(180, 60, 60, 255))
    d.rectangle((cx + 13, cy + 6, cx + 21, cy + 12), fill=(60, 80, 200, 255))
    # field particles orbiting
    for angle_deg in [20, 80, 140, 200, 260, 320]:
        angle = math.radians(angle_deg)
        x = cx + int(20 * math.cos(angle))
        y = cy - 4 + int(8 * math.sin(angle))
        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(160, 240, 255, 200))
    gen(img, ROOT / "assets/ui/icons/weapon_magnetic_field.png")


# ── GRUP D – World Bomb Sprite ───────────────────────────────────────────────

def sprite_world_bomb() -> None:
    """48×48 sci-fi bomb: dark red metal body, glowing red core, danger feel."""
    img = canvas(48, 48)
    d = ImageDraw.Draw(img)
    cx, cy = 24, 28
    # outer danger glow
    for r, a in [(20, 30), (16, 60)]:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(200, 30, 30, a))
    # body
    d.ellipse((cx - 14, cy - 14, cx + 14, cy + 14),
              fill=(80, 20, 20, 255), outline=(140, 40, 40, 255), width=2)
    # metal highlight band
    d.arc((cx - 12, cy - 12, cx + 12, cy + 12), start=200, end=290,
          fill=(160, 80, 80, 200), width=3)
    # glowing core
    for r, a in [(5, 100), (4, 180), (3, 240)]:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 60, 60, a))
    # indicator bolts
    for angle_deg in [0, 90, 180, 270]:
        angle = math.radians(angle_deg)
        bx = cx + int(11 * math.cos(angle))
        by = cy + int(11 * math.sin(angle))
        d.ellipse((bx - 2, by - 2, bx + 2, by + 2), fill=(180, 60, 60, 220))
    # fuse cord
    d.line([(cx + 6, cy - 14), (cx + 12, cy - 22)], fill=(180, 140, 80, 255), width=2)
    d.ellipse((cx + 10, cy - 25, cx + 16, cy - 19), fill=(255, 200, 60, 220))
    gen(img, ROOT / "assets/vfx/sprite_world_bomb.png")


# ── main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    print("\n── GRUP A: Projectile sprites ──")
    proj_rocket_blaster()
    proj_octo_gun()
    proj_blitz_bomb()
    proj_orbital_mayhem()

    print("\n── GRUP B: VFX effects ──")
    vfx_explosion_burst()
    vfx_electric_arc()
    vfx_sonic_jump_flash()
    vfx_sonic_jump_ring()
    vfx_spin_laser_beam()
    vfx_freeze_burst()
    vfx_magnetic_pulse()
    vfx_rocket_smoke_trail()
    vfx_orbital_streak()
    vfx_world_bomb_indicator()

    print("\n── GRUP C: Weapon icons ──")
    icon_rocket_blaster()
    icon_octo_gun()
    icon_sonic_jumper()
    icon_blitz_bomb()
    icon_spin_laser()
    icon_orbital_mayhem()
    icon_magnetic_field()

    print("\n── GRUP D: World objects ──")
    sprite_world_bomb()

    print("\n✓ 22 assets generated (PNG + .import each)\n")


if __name__ == "__main__":
    main()
