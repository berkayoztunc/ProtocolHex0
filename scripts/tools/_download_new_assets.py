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
BASE_DL = "https://api.pixellab.ai/mcp/map-objects/{}/download"

ASSETS = {
    # ── GRUP A: Projectile sprites ──────────────────────────────────────────
    "23b6dee5-dd70-4f7e-93ed-e113aee98fe0": (BASE_DL.format("23b6dee5-dd70-4f7e-93ed-e113aee98fe0"), "assets/weapons/proj_rocket_blaster.png"),
    "a9ad7a19-ff6e-45e5-b03e-0a1b9db0a640": (BASE_DL.format("a9ad7a19-ff6e-45e5-b03e-0a1b9db0a640"), "assets/weapons/proj_octo_gun.png"),
    "9cda3432-e3e3-44fe-bcbb-bf20714d6317": (BASE_DL.format("9cda3432-e3e3-44fe-bcbb-bf20714d6317"), "assets/weapons/proj_blitz_bomb.png"),
    "75dab7b3-94dd-47a0-91ef-02ebc2910d4a": (BASE_DL.format("75dab7b3-94dd-47a0-91ef-02ebc2910d4a"), "assets/weapons/proj_orbital_mayhem.png"),

    # ── GRUP B: VFX effects ─────────────────────────────────────────────────
    "11cf6319-a2ab-47fc-9171-f9ec1de324cb": (BASE_DL.format("11cf6319-a2ab-47fc-9171-f9ec1de324cb"), "assets/vfx/vfx_explosion_burst.png"),
    "91b7e75b-bf62-4ef3-9b64-e619a0f9486d": (BASE_DL.format("91b7e75b-bf62-4ef3-9b64-e619a0f9486d"), "assets/vfx/vfx_electric_arc.png"),
    "54011643-00ee-4512-bce6-39c087c41fe1": (BASE_DL.format("54011643-00ee-4512-bce6-39c087c41fe1"), "assets/vfx/vfx_sonic_jump_flash.png"),
    "faac9c0c-a015-413e-8b80-0a1d46346320": (BASE_DL.format("faac9c0c-a015-413e-8b80-0a1d46346320"), "assets/vfx/vfx_sonic_jump_ring.png"),
    "a013afa5-a07a-4d8c-952a-1d3d7db732ef": (BASE_DL.format("a013afa5-a07a-4d8c-952a-1d3d7db732ef"), "assets/vfx/vfx_spin_laser_beam.png"),
    "4506cdfc-2921-476a-9197-733925ba0d42": (BASE_DL.format("4506cdfc-2921-476a-9197-733925ba0d42"), "assets/vfx/vfx_freeze_burst.png"),
    "ed68993c-f5c8-42df-bdfa-a5184fecc707": (BASE_DL.format("ed68993c-f5c8-42df-bdfa-a5184fecc707"), "assets/vfx/vfx_magnetic_pulse.png"),
    "7bb39723-f1c7-4b70-b9d6-bd3911b570f6": (BASE_DL.format("7bb39723-f1c7-4b70-b9d6-bd3911b570f6"), "assets/vfx/vfx_rocket_smoke_trail.png"),
    "37ba5c16-902b-427a-9b43-460a060ccf98": (BASE_DL.format("37ba5c16-902b-427a-9b43-460a060ccf98"), "assets/vfx/vfx_orbital_streak.png"),
    "3376297b-31a5-4d3a-8e44-a473fd893740": (BASE_DL.format("3376297b-31a5-4d3a-8e44-a473fd893740"), "assets/vfx/vfx_world_bomb_indicator.png"),

    # ── GRUP C: Weapon icons ─────────────────────────────────────────────────
    "da762930-9965-4170-a26a-7cffaaff350c": (BASE_DL.format("da762930-9965-4170-a26a-7cffaaff350c"), "assets/ui/icons/weapon_rocket_blaster.png"),
    "a35163e0-8cd6-4573-848a-aaa10572201b": (BASE_DL.format("a35163e0-8cd6-4573-848a-aaa10572201b"), "assets/ui/icons/weapon_octo_gun.png"),
    "e1d76c46-552a-4138-be46-451b482d81a9": (BASE_DL.format("e1d76c46-552a-4138-be46-451b482d81a9"), "assets/ui/icons/weapon_sonic_jumper.png"),
    "07e900b4-4763-4606-9baa-5fd65d51afb1": (BASE_DL.format("07e900b4-4763-4606-9baa-5fd65d51afb1"), "assets/ui/icons/weapon_blitz_bomb.png"),
    "f93cd88d-9146-4149-aac9-5f7a6071ec92": (BASE_DL.format("f93cd88d-9146-4149-aac9-5f7a6071ec92"), "assets/ui/icons/weapon_spin_laser.png"),
    "2db65f27-d925-46cb-8185-3bd4a68b06cc": (BASE_DL.format("2db65f27-d925-46cb-8185-3bd4a68b06cc"), "assets/ui/icons/weapon_orbital_mayhem.png"),
    "ccb9d2c6-6895-4bad-a343-0ba138284586": (BASE_DL.format("ccb9d2c6-6895-4bad-a343-0ba138284586"), "assets/ui/icons/weapon_magnetic_field.png"),

    # ── GRUP D: World objects ────────────────────────────────────────────────
    "b9053797-d62b-417c-b419-24080d5a017c": (BASE_DL.format("b9053797-d62b-417c-b419-24080d5a017c"), "assets/vfx/sprite_world_bomb.png"),
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
