#!/usr/bin/env python3
"""
Adds nearest-neighbour filter to all background tile import files.
texture_filter=0  → Nearest (pixel-perfect, no bleeding)
texture_repeat=1  → Enabled (seamless tiling)
"""
import glob, re

EXTRA_PARAMS = """\
texture_filter=0
texture_repeat=1
process/fix_alpha_border=false
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""

patterns = [
    "assets/backgrounds/flat_tile_*.png.import",
    "assets/backgrounds/flat_new_*.png.import",
    "assets/backgrounds/pixellab_topdown_*.png.import",
]

updated = 0
for pat in patterns:
    for path in glob.glob(pat):
        with open(path, "r") as f:
            content = f.read()

        # If texture_filter already exists, just update its value
        if "texture_filter" in content:
            content = re.sub(r"texture_filter=\d+", "texture_filter=0", content)
            content = re.sub(r"texture_repeat=\d+", "texture_repeat=1", content)
        else:
            # Insert right below the compress/mode line
            content = re.sub(
                r"(compress/mode=\d+\n)",
                r"\1" + EXTRA_PARAMS,
                content,
                count=1,
            )

        # process/fix_alpha_border zaten varsa false yap
        content = re.sub(r"process/fix_alpha_border=true", "process/fix_alpha_border=false", content)

        with open(path, "w") as f:
            f.write(content)
        print(f"  ✓ {path}")
        updated += 1

print(f"\n{updated} import file(s) updated.")
