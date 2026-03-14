from pathlib import Path
import random

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def save(img: Image.Image, path: Path) -> None:
    ensure_parent(path)
    img.save(path)


def make_canvas(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def make_enemy(path: Path, elite: bool = False) -> None:
    img = make_canvas(64, 64)
    d = ImageDraw.Draw(img)
    body = (180, 40, 70, 255) if not elite else (190, 70, 210, 255)
    d.ellipse((22, 10, 42, 28), fill=(220, 220, 235, 255), outline=(20, 20, 30, 255), width=2)
    d.rectangle((20, 28, 44, 52), fill=body, outline=(20, 20, 30, 255), width=2)
    d.rectangle((16, 34, 20, 50), fill=body)
    d.rectangle((44, 34, 48, 50), fill=body)
    if elite:
        d.polygon([(24, 8), (28, 2), (32, 8), (36, 2), (40, 8)], fill=(250, 220, 120, 255))
    save(img, path)


def make_gem(path: Path, color, glow) -> None:
    size = 48
    img = make_canvas(size, size)
    d = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    r = size // 3
    for i in range(4, 0, -1):
        rr = r + i * 3
        a = int(glow[3] * (0.15 * i))
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=(glow[0], glow[1], glow[2], a))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color, outline=(20, 20, 30, 255), width=2)
    save(img, path)


def make_chest(path: Path) -> None:
    img = make_canvas(64, 64)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((12, 24, 52, 48), radius=6, fill=(74, 58, 40, 255), outline=(20, 20, 30, 255), width=3)
    d.rounded_rectangle((12, 18, 52, 30), radius=6, fill=(110, 85, 55, 255), outline=(20, 20, 30, 255), width=3)
    d.rectangle((29, 28, 35, 40), fill=(210, 170, 70, 255))
    save(img, path)


def make_projectile(path: Path, primary, secondary) -> None:
    img = make_canvas(32, 32)
    d = ImageDraw.Draw(img)
    d.polygon([(4, 16), (22, 10), (28, 16), (22, 22)], fill=primary)
    d.ellipse((20, 12, 28, 20), fill=secondary)
    save(img, path)


def make_panel(path: Path, w: int, h: int, fill, border) -> None:
    img = make_canvas(w, h)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((2, 2, w - 3, h - 3), radius=max(4, min(w, h) // 6), fill=fill, outline=border, width=3)
    save(img, path)


def make_bar_fill(path: Path, c1, c2) -> None:
    w, h = 256, 24
    img = make_canvas(w, h)
    d = ImageDraw.Draw(img)
    for x in range(w):
        t = x / max(1, w - 1)
        c = tuple(int(c1[i] * (1 - t) + c2[i] * t) for i in range(3)) + (255,)
        d.line((x, 4, x, h - 5), fill=c)
    d.rounded_rectangle((1, 1, w - 2, h - 2), radius=8, outline=(20, 20, 30, 255), width=2)
    save(img, path)


def make_bar_frame(path: Path) -> None:
    w, h = 256, 24
    img = make_canvas(w, h)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((1, 1, w - 2, h - 2), radius=8, fill=(0, 0, 0, 0), outline=(230, 235, 250, 255), width=3)
    save(img, path)


def make_icon(path: Path, kind: str) -> None:
    size = 64
    img = make_canvas(size, size)
    d = ImageDraw.Draw(img)
    fg = (230, 240, 255, 255)
    d.rounded_rectangle((4, 4, size - 5, size - 5), radius=12, fill=(45, 60, 85, 220), outline=(130, 160, 210, 255), width=2)

    if kind == "bomb":
        d.ellipse((18, 20, 46, 48), fill=fg)
        d.line((32, 14, 40, 22), fill=(255, 220, 120, 255), width=3)
    elif kind == "heal":
        d.rectangle((28, 18, 36, 46), fill=fg)
        d.rectangle((18, 28, 46, 36), fill=fg)
    elif kind == "dash":
        d.polygon([(14, 38), (32, 20), (32, 30), (50, 30), (32, 48), (32, 38)], fill=fg)
    elif kind == "target":
        d.ellipse((16, 16, 48, 48), outline=fg, width=3)
        d.line((32, 10, 32, 54), fill=fg, width=2)
        d.line((10, 32, 54, 32), fill=fg, width=2)
    elif kind == "tree":
        d.rectangle((30, 20, 34, 46), fill=fg)
        d.line((32, 20, 22, 30), fill=fg, width=3)
        d.line((32, 26, 42, 36), fill=fg, width=3)
    elif kind == "menu":
        for y in (22, 32, 42):
            d.rounded_rectangle((16, y, 48, y + 4), radius=2, fill=fg)
    elif kind == "kill":
        d.polygon([(32, 16), (44, 26), (40, 46), (24, 46), (20, 26)], outline=fg, fill=(0, 0, 0, 0), width=3)
        d.ellipse((24, 30, 29, 35), fill=fg)
        d.ellipse((35, 30, 40, 35), fill=fg)
    elif kind == "chest":
        d.rectangle((16, 26, 48, 46), fill=fg)
        d.rectangle((16, 20, 48, 30), fill=(180, 190, 220, 255))
    elif kind == "xp":
        d.text((22, 22), "XP", fill=fg)
    elif kind == "shield":
        d.polygon([(32, 14), (46, 22), (42, 44), (32, 52), (22, 44), (18, 22)], fill=fg)
    else:
        d.ellipse((24, 24, 40, 40), fill=fg)

    save(img, path)


def make_vfx_ring(path: Path, color) -> None:
    size = 192
    img = make_canvas(size, size)
    d = ImageDraw.Draw(img)
    cx = size // 2
    for r, a in [(72, 180), (58, 130), (44, 90)]:
        d.ellipse((cx - r, cx - r, cx + r, cx + r), outline=(color[0], color[1], color[2], a), width=5)
    save(img, path)


def make_hit_spark(path: Path) -> None:
    img = make_canvas(64, 64)
    d = ImageDraw.Draw(img)
    pts = [(32, 8), (38, 24), (56, 24), (42, 34), (48, 54), (32, 40), (16, 54), (22, 34), (8, 24), (26, 24)]
    d.polygon(pts, fill=(255, 220, 120, 235), outline=(255, 120, 60, 255))
    save(img, path)


def make_background(path: Path) -> None:
    w, h = 1280, 720
    img = Image.new("RGBA", (w, h), (8, 12, 20, 255))
    d = ImageDraw.Draw(img)

    for y in range(h):
        t = y / max(1, h - 1)
        c = (int(10 + 25 * t), int(14 + 20 * t), int(28 + 40 * t), 255)
        d.line((0, y, w, y), fill=c)

    random.seed(7)
    for _ in range(120):
        x = random.randint(0, w - 1)
        y = random.randint(h // 3, h - 1)
        bw = random.randint(8, 20)
        bh = random.randint(40, 180)
        d.rectangle((x, y - bh, x + bw, y), fill=(20, 35, 60, 120))

    for _ in range(30):
        x = random.randint(0, w - 1)
        y = random.randint(0, h - 1)
        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(80, 180, 255, 120))

    save(img, path)


def copy_south_to_missing_directions() -> None:
    base = ROOT / "assets/characters/genihero_ui/animations"
    for anim in ["breathing-idle", "walk"]:
        south = base / anim / "south"
        if not south.exists():
            continue
        for direction in ["north", "east", "west"]:
            target = base / anim / direction
            target.mkdir(parents=True, exist_ok=True)
            for i in range(6):
                src = south / f"frame_{i:03d}.png"
                dst = target / f"frame_{i:03d}.png"
                if src.exists() and not dst.exists():
                    Image.open(src).save(dst)


def main() -> None:
    copy_south_to_missing_directions()

    make_enemy(ROOT / "assets/enemies/enemy_basic.png", elite=False)
    make_enemy(ROOT / "assets/enemies/enemy_elite.png", elite=True)

    make_gem(ROOT / "assets/pickups/xp_gem_small.png", (90, 255, 120, 255), (70, 255, 100, 220))
    make_gem(ROOT / "assets/pickups/xp_gem_medium.png", (90, 170, 255, 255), (70, 150, 255, 220))
    make_gem(ROOT / "assets/pickups/xp_gem_large.png", (255, 210, 90, 255), (255, 210, 80, 220))
    make_chest(ROOT / "assets/pickups/chest_closed.png")

    projectiles = {
        "proj_plasma_rifle.png": ((80, 230, 255, 255), (220, 255, 255, 230)),
        "proj_nano_swarm.png": ((110, 255, 160, 255), (230, 255, 235, 230)),
        "proj_tesla_emitter.png": ((130, 200, 255, 255), (240, 250, 255, 230)),
        "proj_scatter_pellet.png": ((255, 170, 90, 255), (255, 230, 180, 230)),
        "proj_orbital_sentinel.png": ((255, 220, 90, 255), (255, 245, 200, 230)),
        "proj_railgun.png": ((255, 80, 90, 255), (255, 210, 210, 230)),
        "proj_void_launcher.png": ((140, 90, 210, 255), (220, 200, 255, 230)),
        "proj_arc_blaster.png": ((120, 180, 255, 255), (230, 245, 255, 230)),
        "proj_gravity_pulse.png": ((90, 140, 255, 255), (210, 225, 255, 230)),
    }
    for name, colors in projectiles.items():
        make_projectile(ROOT / "assets/weapons" / name, *colors)

    make_panel(ROOT / "assets/ui/panels/panel_main_9slice.png", 128, 128, (24, 32, 44, 242), (95, 130, 180, 255))
    make_panel(ROOT / "assets/ui/panels/panel_secondary_9slice.png", 128, 128, (20, 26, 36, 228), (75, 100, 140, 255))
    make_panel(ROOT / "assets/ui/panels/button_primary_normal.png", 96, 32, (35, 60, 95, 255), (120, 170, 240, 255))
    make_panel(ROOT / "assets/ui/panels/button_primary_hover.png", 96, 32, (50, 80, 120, 255), (150, 210, 255, 255))
    make_panel(ROOT / "assets/ui/panels/button_primary_pressed.png", 96, 32, (25, 45, 75, 255), (100, 150, 220, 255))
    make_panel(ROOT / "assets/ui/panels/button_primary_disabled.png", 96, 32, (45, 45, 55, 180), (95, 95, 110, 220))
    make_panel(ROOT / "assets/ui/panels/input_frame.png", 192, 48, (22, 30, 40, 220), (110, 130, 160, 255))
    make_panel(ROOT / "assets/ui/panels/slider_track.png", 192, 24, (28, 35, 46, 220), (90, 110, 136, 255))
    make_panel(ROOT / "assets/ui/panels/slider_thumb.png", 24, 24, (120, 180, 255, 255), (220, 240, 255, 255))

    make_bar_fill(ROOT / "assets/ui/bars/bar_health_fill.png", (220, 60, 80, 255), (255, 160, 170, 255))
    make_bar_frame(ROOT / "assets/ui/bars/bar_health_frame.png")
    make_bar_fill(ROOT / "assets/ui/bars/bar_xp_fill.png", (60, 180, 255, 255), (150, 235, 255, 255))
    make_bar_frame(ROOT / "assets/ui/bars/bar_xp_frame.png")

    icons = {
        "icon_bomb.png": "bomb",
        "icon_heal.png": "heal",
        "icon_dash.png": "dash",
        "icon_targeting.png": "target",
        "icon_perk_tree.png": "tree",
        "icon_menu.png": "menu",
        "icon_kill.png": "kill",
        "icon_chest.png": "chest",
        "icon_xp.png": "xp",
        "icon_shield.png": "shield",
        "weapon_plasma_rifle.png": "dot",
        "weapon_nano_swarm.png": "dot",
        "weapon_tesla_emitter.png": "dot",
        "weapon_scatter_cannon.png": "dot",
        "weapon_orbital_sentinel.png": "dot",
        "weapon_railgun.png": "dot",
        "weapon_void_launcher.png": "dot",
        "weapon_arc_blaster.png": "dot",
        "weapon_gravity_pulse.png": "dot",
    }
    for name, kind in icons.items():
        make_icon(ROOT / "assets/ui/icons" / name, kind)

    make_vfx_ring(ROOT / "assets/vfx/vfx_void_explosion_ring.png", (150, 90, 255, 255))
    make_vfx_ring(ROOT / "assets/vfx/vfx_gravity_wave_ring.png", (90, 150, 255, 255))
    make_hit_spark(ROOT / "assets/vfx/vfx_hit_spark.png")
    make_background(ROOT / "assets/ui/backgrounds/start_menu_bg.png")

    print("placeholder assets generated")


if __name__ == "__main__":
    main()
