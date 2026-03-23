"""Verify all 22 PixelLab assets are valid PNGs on disk."""
import os

ROOT = "/Users/berkay/Desktop/work/geni-hero"

def is_valid_png(path):
    try:
        with open(path, 'rb') as f:
            return f.read(8) == b'\x89PNG\r\n\x1a\n'
    except Exception:
        return False

files = [
    "assets/weapons/proj_rocket_blaster.png",
    "assets/weapons/proj_octo_gun.png",
    "assets/weapons/proj_blitz_bomb.png",
    "assets/weapons/proj_orbital_mayhem.png",
    "assets/vfx/vfx_explosion_burst.png",
    "assets/vfx/vfx_electric_arc.png",
    "assets/vfx/vfx_sonic_jump_flash.png",
    "assets/vfx/vfx_sonic_jump_ring.png",
    "assets/vfx/vfx_spin_laser_beam.png",
    "assets/vfx/vfx_freeze_burst.png",
    "assets/vfx/vfx_magnetic_pulse.png",
    "assets/vfx/vfx_rocket_smoke_trail.png",
    "assets/vfx/vfx_orbital_streak.png",
    "assets/vfx/vfx_world_bomb_indicator.png",
    "assets/ui/icons/weapon_rocket_blaster.png",
    "assets/ui/icons/weapon_octo_gun.png",
    "assets/ui/icons/weapon_sonic_jumper.png",
    "assets/ui/icons/weapon_blitz_bomb.png",
    "assets/ui/icons/weapon_spin_laser.png",
    "assets/ui/icons/weapon_orbital_mayhem.png",
    "assets/ui/icons/weapon_magnetic_field.png",
    "assets/vfx/sprite_world_bomb.png",
]

ok = 0
for rel in files:
    full = os.path.join(ROOT, rel)
    valid = is_valid_png(full)
    size = os.path.getsize(full) if os.path.exists(full) else 0
    print(f"  {'OK ' if valid else 'BAD'}  {rel}  ({size:,}b)")
    if valid:
        ok += 1

print(f"\n{ok}/22 valid PNGs")
