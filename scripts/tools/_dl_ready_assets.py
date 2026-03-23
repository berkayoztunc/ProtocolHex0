"""Download the 16 ready PixelLab assets to their correct paths."""
import urllib.request
import os

BASE_URL = "https://api.pixellab.ai/mcp/map-objects/{}/download"
WORKSPACE = "/Users/berkay/Desktop/work/geni-hero"

downloads = [
    ("23b6dee5-dd70-4f7e-93ed-e113aee98fe0", "assets/weapons/proj_rocket_blaster.png"),
    ("9cda3432-e3e3-44fe-bcbb-bf20714d6317", "assets/weapons/proj_blitz_bomb.png"),
    ("91b7e75b-bf62-4ef3-9b64-e619a0f9486d", "assets/vfx/vfx_electric_arc.png"),
    ("54011643-00ee-4512-bce6-39c087c41fe1", "assets/vfx/vfx_sonic_jump_flash.png"),
    ("ed68993c-f5c8-42df-bdfa-a5184fecc707", "assets/vfx/vfx_magnetic_pulse.png"),
    ("7bb39723-f1c7-4b70-b9d6-bd3911b570f6", "assets/vfx/vfx_rocket_smoke_trail.png"),
    ("37ba5c16-902b-427a-9b43-460a060ccf98", "assets/vfx/vfx_orbital_streak.png"),
    ("3376297b-31a5-4d3a-8e44-a473fd893740", "assets/vfx/vfx_world_bomb_indicator.png"),
    ("da762930-9965-4170-a26a-7cffaaff350c", "assets/ui/icons/weapon_rocket_blaster.png"),
    ("a35163e0-8cd6-4573-848a-aaa10572201b", "assets/ui/icons/weapon_octo_gun.png"),
    ("e1d76c46-552a-4138-be46-451b482d81a9", "assets/ui/icons/weapon_sonic_jumper.png"),
    ("07e900b4-4763-4606-9baa-5fd65d51afb1", "assets/ui/icons/weapon_blitz_bomb.png"),
    ("f93cd88d-9146-4149-aac9-5f7a6071ec92", "assets/ui/icons/weapon_spin_laser.png"),
    ("2db65f27-d925-46cb-8185-3bd4a68b06cc", "assets/ui/icons/weapon_orbital_mayhem.png"),
    ("ccb9d2c6-6895-4bad-a343-0ba138284586", "assets/ui/icons/weapon_magnetic_field.png"),
    ("b9053797-d62b-417c-b419-24080d5a017c", "assets/vfx/sprite_world_bomb.png"),
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
