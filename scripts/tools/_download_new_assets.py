#!/usr/bin/env python3
"""
Download finalized PixelLab map-object assets and replace PIL placeholders.

Usage:
  1. Generate each asset at https://pixellab.ai or via mcp_pixellab calls
  2. Run get_map_object for each completed object_id to get its download_url
  3. Paste object_id -> url into DOWNLOAD_URLS below
  4. Run:  python3 scripts/tools/_download_new_assets.py
  5. Verify the PNGs replaced the PIL placeholders (file sizes will be larger)

.import files do NOT need to change — Godot re-imports on next project open.
"""
import hashlib
import os
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# ─── Fill these in after PixelLab generation ─────────────────────────────────
# Format:  "object_id": ("https://...", "relative/dest/path.png")
ASSETS = {
    # ── GRUP A: Projectile sprites ──────────────────────────────────────────
    # "FILL_A1": ("https://...", "assets/weapons/proj_rocket_blaster.png"),
    # "FILL_A2": ("https://...", "assets/weapons/proj_octo_gun.png"),
    # "FILL_A3": ("https://...", "assets/weapons/proj_blitz_bomb.png"),
    # "FILL_A4": ("https://...", "assets/weapons/proj_orbital_mayhem.png"),

    # ── GRUP B: VFX effects ─────────────────────────────────────────────────
    # "FILL_B1":  ("https://...", "assets/vfx/vfx_explosion_burst.png"),
    # "FILL_B2":  ("https://...", "assets/vfx/vfx_electric_arc.png"),
    # "FILL_B3":  ("https://...", "assets/vfx/vfx_sonic_jump_flash.png"),
    # "FILL_B4":  ("https://...", "assets/vfx/vfx_sonic_jump_ring.png"),
    # "FILL_B5":  ("https://...", "assets/vfx/vfx_spin_laser_beam.png"),
    # "FILL_B6":  ("https://...", "assets/vfx/vfx_freeze_burst.png"),
    # "FILL_B7":  ("https://...", "assets/vfx/vfx_magnetic_pulse.png"),
    # "FILL_B8":  ("https://...", "assets/vfx/vfx_rocket_smoke_trail.png"),
    # "FILL_B9":  ("https://...", "assets/vfx/vfx_orbital_streak.png"),
    # "FILL_B10": ("https://...", "assets/vfx/vfx_world_bomb_indicator.png"),

    # ── GRUP C: Weapon icons ─────────────────────────────────────────────────
    # "FILL_C1": ("https://...", "assets/ui/icons/weapon_rocket_blaster.png"),
    # "FILL_C2": ("https://...", "assets/ui/icons/weapon_octo_gun.png"),
    # "FILL_C3": ("https://...", "assets/ui/icons/weapon_sonic_jumper.png"),
    # "FILL_C4": ("https://...", "assets/ui/icons/weapon_blitz_bomb.png"),
    # "FILL_C5": ("https://...", "assets/ui/icons/weapon_spin_laser.png"),
    # "FILL_C6": ("https://...", "assets/ui/icons/weapon_orbital_mayhem.png"),
    # "FILL_C7": ("https://...", "assets/ui/icons/weapon_magnetic_field.png"),

    # ── GRUP D: World objects ────────────────────────────────────────────────
    # "FILL_D1": ("https://...", "assets/vfx/sprite_world_bomb.png"),
}


def download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"  DL   {dest.relative_to(ROOT)}", end="  ", flush=True)
    urllib.request.urlretrieve(url, dest)
    size_kb = dest.stat().st_size // 1024
    print(f"({size_kb} KB)")


def update_import_uid(png_path: Path) -> None:
    """Refresh the uid in the .import file so Godot re-processes it."""
    import_path = Path(str(png_path) + ".import")
    if not import_path.exists():
        return
    content = import_path.read_text()
    rel = png_path.relative_to(ROOT).as_posix()
    new_uid = hashlib.md5((rel + "v2").encode()).hexdigest()[:14]
    import_lines = []
    for line in content.splitlines():
        if line.startswith('uid="uid://'):
            line = f'uid="uid://{new_uid}"'
        import_lines.append(line)
    import_path.write_text("\n".join(import_lines) + "\n")


def main() -> None:
    ready = {k: v for k, v in ASSETS.items() if not k.startswith("FILL_")}
    if not ready:
        print("No assets to download — fill in ASSETS dict with object IDs and URLs.")
        print(f"Total entries pending: {len(ASSETS)}")
        return

    print(f"\nDownloading {len(ready)} / {len(ASSETS)} assets...\n")
    errors = []
    for obj_id, (url, rel_dest) in ready.items():
        dest = ROOT / rel_dest
        try:
            download(url, dest)
            update_import_uid(dest)
        except Exception as e:
            print(f"  ERR  {rel_dest}: {e}")
            errors.append(rel_dest)

    print(f"\n✓ Done. {len(ready) - len(errors)} downloaded, {len(errors)} failed.")
    if errors:
        print("Failed:")
        for e in errors:
            print(f"  - {e}")
    pending = len(ASSETS) - len(ready)
    if pending:
        print(f"\n{pending} assets still need object IDs (still commented out in ASSETS dict).")


if __name__ == "__main__":
    main()
