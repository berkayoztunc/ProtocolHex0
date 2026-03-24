import hashlib
import os

base = "/Users/berkay/Desktop/work/geni-hero/assets/tile_backgrounds"

TEMPLATE = (
    "[remap]\n\n"
    'importer="texture"\n'
    'type="CompressedTexture2D"\n'
    'uid="uid://{uid}"\n'
    'path="res://.godot/imported/{fname}-{hash}.ctex"\n'
    "metadata={{\n"
    '"vram_texture": false\n'
    "}}\n\n"
    "[deps]\n\n"
    'source_file="res://assets/tile_backgrounds/{fname}"\n'
    'dest_files=["res://.godot/imported/{fname}-{hash}.ctex"]\n\n'
    "[params]\n\n"
    "compress/mode=0\n"
    "compress/high_quality=false\n"
    "compress/lossy_quality=0.7\n"
    "compress/uastc_level=0\n"
    "compress/rdo_quality_loss=0.0\n"
    "compress/hdr_compression=1\n"
    "compress/normal_map=0\n"
    "compress/channel_pack=0\n"
    "mipmaps/generate=false\n"
    "mipmaps/limit=-1\n"
    "roughness/mode=0\n"
    'roughness/src_normal=""\n'
    "process/channel_remap/red=0\n"
    "process/channel_remap/green=1\n"
    "process/channel_remap/blue=2\n"
    "process/channel_remap/alpha=3\n"
    "process/fix_alpha_border=false\n"
    "process/premult_alpha=false\n"
    "process/normal_map_invert_y=false\n"
    "process/hdr_as_srgb=false\n"
    "process/hdr_clamp_exposure=false\n"
    "process/size_limit=0\n"
    "detect_3d/compress_to=1\n"
)

for i in range(1, 18):
    fname = "tile_%d.png" % i
    src_path = "res://assets/tile_backgrounds/" + fname
    h = hashlib.md5(src_path.encode()).hexdigest()
    uid_raw = hashlib.sha1(src_path.encode()).hexdigest()[:13]
    content = TEMPLATE.format(uid=uid_raw, fname=fname, hash=h)
    out_path = os.path.join(base, fname + ".import")
    with open(out_path, "w") as f:
        f.write(content)
    print("Created: %s  uid=%s" % (fname + ".import", uid_raw))

print("Done.")
