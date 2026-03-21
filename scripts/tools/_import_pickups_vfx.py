#!/usr/bin/env python3
import os, hashlib, uuid

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

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

FILES = [
    "assets/pickups/xp_gem_small.png",
    "assets/pickups/xp_gem_medium.png",
    "assets/pickups/xp_gem_large.png",
    "assets/vfx/vfx_hit_spark.png",
    "assets/vfx/vfx_gravity_wave_ring.png",
    "assets/vfx/vfx_void_explosion_ring.png",
]

for rel in FILES:
    abs_path = os.path.join(PROJECT_ROOT, rel)
    if not os.path.isfile(abs_path):
        print(f"SKIP (missing): {rel}")
        continue
    import_path = abs_path + ".import"
    if os.path.isfile(import_path):
        print(f"EXISTS: {rel}")
        continue
    basename = os.path.splitext(os.path.basename(abs_path))[0]
    with open(abs_path, "rb") as f:
        md5 = hashlib.md5(f.read()).hexdigest()
    uid = hashlib.md5(uuid.uuid4().bytes).hexdigest()[:14]
    content = IMPORT_TEMPLATE.format(uid=uid, respath=rel.replace("\\", "/"), basename=basename, md5=md5)
    with open(import_path, "w") as f:
        f.write(content)
    print(f"CREATED: {rel}")

print("Done.")
