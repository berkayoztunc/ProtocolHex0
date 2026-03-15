#!/usr/bin/env python3
"""Generate Godot .import files for PixelLab enemy character assets and
update the static enemy placeholder sprites with generated rotation images."""
import os
import shutil
import hashlib
import uuid

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

IMPORT_TEMPLATE = """[remap]

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
    # Godot-style base62 uid (simplified: use truncated hex)
    return hashlib.md5(raw).hexdigest()[:14]


def create_import(png_abs: str) -> None:
    if not os.path.isfile(png_abs):
        return
    import_path = png_abs + ".import"
    if os.path.isfile(import_path):
        return  # already exists
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
    print(f"  + created: {import_path}")


def process_character_folder(char_name: str) -> None:
    char_dir = os.path.join(PROJECT_ROOT, "assets", "characters", char_name)
    if not os.path.isdir(char_dir):
        print(f"SKIP (folder missing): {char_dir}")
        return
    print(f"\n=== {char_name} ===")
    count = 0
    for dirpath, _, filenames in os.walk(char_dir):
        for fn in sorted(filenames):
            if fn.endswith(".png"):
                create_import(os.path.join(dirpath, fn))
                count += 1
    print(f"  {count} PNG files processed")

    # Copy south rotation image to static enemy sprite slot
    enemy_key = "enemy_elite" if char_name == "enemy_elite" else "enemy_basic"
    south_src = os.path.join(char_dir, "rotations", "south.png")
    static_dst = os.path.join(PROJECT_ROOT, "assets", "enemies", f"{enemy_key}.png")
    if os.path.isfile(south_src):
        shutil.copy2(south_src, static_dst)
        print(f"  → updated static sprite: assets/enemies/{enemy_key}.png")


if __name__ == "__main__":
    process_character_folder("enemy_basic")
    process_character_folder("enemy_elite")
    print("\nDone.")
