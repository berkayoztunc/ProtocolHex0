#!/usr/bin/env python3
"""Download generated PixelLab map objects (XP gems + VFX) and create .import files."""
import os
import hashlib
import uuid
import urllib.request

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

# Map objects: (object_id, dest_relative_path)
# Run get_map_object to get the download_url for each object_id and paste here
MAP_OBJECTS = [
    # XP gems
    ("0e6d1acf-6685-4de4-9b1c-5960eb275a36", "assets/pickups/xp_gem_small.png"),
    ("e06c5fa3-243d-4dd4-af03-6966155d880f", "assets/pickups/xp_gem_medium.png"),
    ("1467eb2f-1401-4123-8fee-10a51dcc7fa7", "assets/pickups/xp_gem_large.png"),
    # VFX
    ("9a633600-1509-4b25-a8d2-ab427c9acae4", "assets/vfx/vfx_hit_spark.png"),
    ("1655f5b7-c879-48fa-9588-ff9e83d24795", "assets/vfx/vfx_gravity_wave_ring.png"),
    ("b2495a46-c08f-4f6c-8477-b71eb458a177", "assets/vfx/vfx_void_explosion_ring.png"),
]

# Paste download URLs from get_map_object responses here (object_id -> url)
DOWNLOAD_URLS = {
    # Fill in after running get_map_object for each completed object
    # "object_id": "https://...",
}


def make_uid() -> str:
    raw = uuid.uuid4().bytes
    return hashlib.md5(raw).hexdigest()[:14]


def create_import_for(png_abs: str) -> None:
    if not os.path.isfile(png_abs):
        return
    import_path = png_abs + ".import"
    rel = os.path.relpath(png_abs, PROJECT_ROOT).replace("\\", "/")
    basename = os.path.splitext(os.path.basename(png_abs))[0]
    with open(png_abs, "rb") as f:
        md5 = hashlib.md5(f.read()).hexdigest()
    content = IMPORT_TEMPLATE.format(uid=make_uid(), respath=rel, basename=basename, md5=md5)
    with open(import_path, "w") as f:
        f.write(content)
    print(f"  import: {import_path}")


def download_asset(url: str, dest: str) -> bool:
    try:
        req = urllib.request.urlopen(url, timeout=30)
        data = req.read()
        if len(data) < 100:
            print(f"  SKIP (too small, likely error): {dest}")
            return False
        with open(dest, "wb") as f:
            f.write(data)
        print(f"  saved ({len(data)} bytes): {dest}")
        return True
    except Exception as e:
        print(f"  ERROR downloading {dest}: {e}")
        return False


if __name__ == "__main__":
    for obj_id, rel_path in MAP_OBJECTS:
        abs_path = os.path.join(PROJECT_ROOT, rel_path)
        if obj_id in DOWNLOAD_URLS:
            url = DOWNLOAD_URLS[obj_id]
            print(f"\n→ {rel_path}")
            if download_asset(url, abs_path):
                create_import_for(abs_path)
        else:
            print(f"\nSKIP (no URL): {rel_path}  (id: {obj_id})")
    print("\nDone.")
