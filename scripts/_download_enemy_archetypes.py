#!/usr/bin/env python3
"""
Download PixelLab enemy archetype animations and integrate them into the Godot project.

Usage:
    python3 scripts/_download_enemy_archetypes.py

What it does:
  1. Downloads the ZIP for each character (skips ones still pending)
  2. Extracts east/west walking-6-frames into
       assets/characters/enemy_{archetype}/animations/walking-6-frames/{direction}/frame_NNN.png
  3. Copies the east rotation image to
       assets/enemies/enemy_{archetype}.png  (static sprite)
  4. Creates .import sidecar files for every PNG so Godot picks them up
"""

import os
import shutil
import hashlib
import json
import subprocess
import sys
import zipfile
import uuid
import tempfile

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ── Character ID registry ──────────────────────────────────────────────────────
ARCHETYPES = {
    "runner":      "1d7fda18-d204-4284-95ef-6e134cf5f878",
    "brute":       "d7c21695-c58b-48a9-9219-0d1adb275331",
    "charger":     "d8b21eb0-c192-4181-8842-3dbf9c4ec5d5",
    "zigzag":      "7423a200-2abc-4e81-86ce-510f87e5c08c",
    "shielded":    "ad8999cf-368f-402b-a068-3e27f15bc936",
    "skirmisher":  "7611be13-1786-4687-b313-61e537cfaf64",
    "sniper":      "c9b5c3a7-2745-49d3-9634-3f52065e0e04",
    "mortar":      "d287eefc-feff-406f-ad3c-313e5a7026cb",
    "suppressor":  "b4bc5a53-bfd9-4b72-8228-1f0433667239",
    "juggernaut":  "f3d3d857-0d35-4c76-9ef0-06f56d4813ca",
}

PIXELLAB_API_BASE = "https://api.pixellab.ai/mcp/characters"

# ── Import template ────────────────────────────────────────────────────────────
IMPORT_TEMPLATE = """\
[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://{uid}"
path="res://.godot/imported/{basename}-{md5}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://{respath}"
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


def make_uid() -> str:
    raw = uuid.uuid4().bytes
    return hashlib.md5(raw).hexdigest()[:14]


def create_import(png_abs: str) -> None:
    if not os.path.isfile(png_abs):
        return
    import_path = png_abs + ".import"
    if os.path.isfile(import_path):
        return
    rel = os.path.relpath(png_abs, PROJECT_ROOT).replace("\\", "/")
    basename = os.path.splitext(os.path.basename(png_abs))[0]
    with open(png_abs, "rb") as f:
        md5 = hashlib.md5(f.read()).hexdigest()
    content = IMPORT_TEMPLATE.format(
        uid=make_uid(),
        respath=rel,
        basename=basename,
        md5=md5,
    )
    with open(import_path, "w") as f:
        f.write(content)
    print(f"    + import: {os.path.relpath(import_path, PROJECT_ROOT)}")


def download_zip(character_id: str, dest_path: str) -> bool:
    """Download character ZIP. Returns True on success, False if still pending."""
    url = f"{PIXELLAB_API_BASE}/{character_id}/download"
    result = subprocess.run(
        ["curl", "--fail", "--silent", "--location", "--output", dest_path, url],
        capture_output=True,
    )
    if result.returncode != 0:
        return False
    # Verify it's a real ZIP (not a JSON error body)
    if os.path.isfile(dest_path) and os.path.getsize(dest_path) > 512:
        try:
            with zipfile.ZipFile(dest_path) as z:
                z.testzip()
            return True
        except zipfile.BadZipFile:
            os.remove(dest_path)
            return False
    if os.path.isfile(dest_path):
        os.remove(dest_path)
    return False


def extract_frames(zip_path: str, archetype: str) -> dict:
    """
    Extract walking-6-frames east/west frames from ZIP.
    Returns { 'east': [abs_paths], 'west': [abs_paths] }
    """
    char_dir = os.path.join(PROJECT_ROOT, "assets", "characters", f"enemy_{archetype}")
    extracted = {}

    with zipfile.ZipFile(zip_path) as z:
        names = z.namelist()
        for direction in ["east", "west"]:
            frame_files = sorted([
                n for n in names
                if f"walking-6-frames/{direction}/" in n and n.endswith(".png")
            ])
            if not frame_files:
                print(f"    ⚠ No {direction} frames found in ZIP")
                continue
            dest_dir = os.path.join(
                char_dir, "animations", "walking-6-frames", direction
            )
            os.makedirs(dest_dir, exist_ok=True)
            extracted[direction] = []
            for i, member in enumerate(frame_files):
                dest_file = os.path.join(dest_dir, f"frame_{i:03d}.png")
                data = z.read(member)
                with open(dest_file, "wb") as f:
                    f.write(data)
                create_import(dest_file)
                extracted[direction].append(dest_file)
            print(f"    ✓ {direction}: {len(frame_files)} frames → {os.path.relpath(dest_dir, PROJECT_ROOT)}")

        # Also save rotation images (east.png → static enemy sprite)
        rotation_files = [n for n in names if "rotations/" in n and n.endswith(".png")]
        rotations_dir = os.path.join(char_dir, "rotations")
        os.makedirs(rotations_dir, exist_ok=True)
        for member in rotation_files:
            direction_name = os.path.splitext(os.path.basename(member))[0]
            dest_file = os.path.join(rotations_dir, f"{direction_name}.png")
            data = z.read(member)
            with open(dest_file, "wb") as f:
                f.write(data)
            create_import(dest_file)

    return extracted


def update_static_sprite(archetype: str) -> None:
    """Copy east rotation image to assets/enemies/enemy_{archetype}.png"""
    src = os.path.join(
        PROJECT_ROOT, "assets", "characters", f"enemy_{archetype}",
        "rotations", "east.png"
    )
    if not os.path.isfile(src):
        return
    dest_dir = os.path.join(PROJECT_ROOT, "assets", "enemies")
    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, f"enemy_{archetype}.png")
    shutil.copy2(src, dest)
    create_import(dest)
    print(f"    → static sprite: assets/enemies/enemy_{archetype}.png")


def save_metadata(archetype: str, character_id: str) -> None:
    char_dir = os.path.join(PROJECT_ROOT, "assets", "characters", f"enemy_{archetype}")
    os.makedirs(char_dir, exist_ok=True)
    meta_path = os.path.join(char_dir, "metadata.json")
    meta = {
        "archetype": archetype,
        "character_id": character_id,
        "animation_style": "east_west_only",
        "template": "walking-6-frames",
    }
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=2)


def process_archetype(archetype: str, character_id: str) -> bool:
    print(f"\n=== enemy_{archetype} ({character_id[:8]}...) ===")
    with tempfile.TemporaryDirectory() as tmpdir:
        zip_path = os.path.join(tmpdir, f"enemy_{archetype}.zip")
        print(f"  ↓ Downloading…")
        if not download_zip(character_id, zip_path):
            print(f"  ⏳ Still processing — skip (re-run later)")
            return False
        print(f"  ✓ Downloaded ZIP ({os.path.getsize(zip_path) // 1024} KB)")
        frames = extract_frames(zip_path, archetype)
        if not frames:
            print(f"  ✗ No frames extracted")
            return False
    update_static_sprite(archetype)
    save_metadata(archetype, character_id)
    return True


def main() -> None:
    print("GeniHero — Enemy Archetype Downloader")
    print("=" * 44)
    success = []
    skipped = []
    for archetype, char_id in ARCHETYPES.items():
        ok = process_archetype(archetype, char_id)
        (success if ok else skipped).append(archetype)

    print("\n" + "=" * 44)
    print(f"✓ Done:    {', '.join(success) or 'none'}")
    if skipped:
        print(f"⏳ Pending: {', '.join(skipped)}")
        print("  Re-run this script after PixelLab finishes generating.")
    print("=" * 44)


if __name__ == "__main__":
    main()
