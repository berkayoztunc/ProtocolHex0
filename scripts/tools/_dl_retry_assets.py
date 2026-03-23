"""Download the 6 remaining PixelLab assets (batch 3 retry)."""
import urllib.request
import os

BASE_URL = "https://api.pixellab.ai/mcp/map-objects/{}/download"
WORKSPACE = "/Users/berkay/Desktop/work/geni-hero"

downloads = [
    ("a9ad7a19-ff6e-45e5-b03e-0a1b9db0a640", "assets/weapons/proj_octo_gun.png"),
    ("75dab7b3-94dd-47a0-91ef-02ebc2910d4a", "assets/weapons/proj_orbital_mayhem.png"),
    ("11cf6319-a2ab-47fc-9171-f9ec1de324cb", "assets/vfx/vfx_explosion_burst.png"),
    ("faac9c0c-a015-413e-8b80-0a1d46346320", "assets/vfx/vfx_sonic_jump_ring.png"),
    ("a013afa5-a07a-4d8c-952a-1d3d7db732ef", "assets/vfx/vfx_spin_laser_beam.png"),
    ("4506cdfc-2921-476a-9197-733925ba0d42", "assets/vfx/vfx_freeze_burst.png"),
]

ok = 0
fail = 0
for obj_id, rel_path in downloads:
    dest = os.path.join(WORKSPACE, rel_path)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    url = BASE_URL.format(obj_id)
    try:
        urllib.request.urlretrieve(url, dest)
        size = os.path.getsize(dest)
        print(f"  OK  {rel_path}  ({size:,} bytes)")
        ok += 1
    except Exception as e:
        print(f"  FAIL {rel_path}: {e}")
        fail += 1

print(f"\nDone: {ok} OK, {fail} failed")
