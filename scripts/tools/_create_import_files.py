#!/usr/bin/env python3
"""Create .import files for newly generated PixelLab assets."""
import os

TEMPLATE = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://{uid}"
path="res://.godot/imported/{filename}-gen.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://{respath}"
dest_files=["res://.godot/imported/{filename}-gen.ctex"]

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

ASSETS = [
    ("assets/ui/panels/button_secondary_normal.png", "gen_btn_sec_normal"),
    ("assets/ui/panels/button_secondary_hover.png", "gen_btn_sec_hover"),
    ("assets/ui/panels/button_secondary_pressed.png", "gen_btn_sec_pressed"),
    ("assets/ui/backgrounds/hero_platform_glow.png", "gen_hero_glow"),
]

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

for respath, uid in ASSETS:
    full = os.path.join(root, respath)
    if not os.path.isfile(full):
        print(f"SKIP (missing source): {respath}")
        continue
    filename = os.path.basename(respath)
    content = TEMPLATE.format(uid=uid, filename=filename, respath=respath)
    import_path = full + ".import"
    with open(import_path, "w") as f:
        f.write(content)
    print(f"OK: {import_path}")

print("Done.")
