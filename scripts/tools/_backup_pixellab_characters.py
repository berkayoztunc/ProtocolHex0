"""
Downloads all PixelLab assets (characters, tilesets, etc.) as ZIP files into assets/backup/.
Skips any asset with status = pending.
"""

import os
import subprocess
import json

BACKUP_DIR = os.path.join(os.path.dirname(__file__), "../../assets/backup")
os.makedirs(BACKUP_DIR, exist_ok=True)

# Subdirectories for organization
os.makedirs(os.path.join(BACKUP_DIR, "characters"), exist_ok=True)
os.makedirs(os.path.join(BACKUP_DIR, "tilesets"), exist_ok=True)

# All characters from PixelLab
CHARACTERS = [
    ("bg_test_soldier",               "64dbb235-a22e-4e1f-8b9a-55f51df7a424"),
    ("GeniHero_Main_v2",              "240c59b4-fb02-4907-8bcc-f62a4df41cd4"),
    ("enemy_skirmisher",              "7611be13-1786-4687-b313-61e537cfaf64"),
    ("enemy_runner",                  "1d7fda18-d204-4284-95ef-6e134cf5f878"),
    ("enemy_juggernaut",              "f3d3d857-0d35-4c76-9ef0-06f56d4813ca"),
    ("enemy_mortar",                  "d287eefc-feff-406f-ad3c-313e5a7026cb"),
    ("enemy_sniper",                  "c9b5c3a7-2745-49d3-9634-3f52065e0e04"),
    ("enemy_suppressor",              "b4bc5a53-bfd9-4b72-8228-1f0433667239"),
    ("enemy_charger",                 "d8b21eb0-c192-4181-8842-3dbf9c4ec5d5"),
    ("enemy_shielded",                "ad8999cf-368f-402b-a068-3e27f15bc936"),
    ("enemy_brute",                   "d7c21695-c58b-48a9-9219-0d1adb275331"),
    ("enemy_zigzag",                  "7423a200-2abc-4e81-86ce-510f87e5c08c"),
    ("GeniHero_CopperGolem_Main",     "005377d5-cadd-45bc-ad38-ec9088dece40"),
    ("GeniHero_EnemyElite",           "2c83f873-51a0-422d-a1ab-3f18792d82ec"),
    ("GeniHero_EnemyBasic",           "1b61b65b-17e5-4b23-890e-f654290cb34d"),
    ("halo4_spaceman",                "3a41a80c-0b60-4726-a8e5-a8c9dfaa26fb"),
    ("GeniHero_UI",                   "4963a649-983d-4890-96ca-92822ffa819e"),
    ("super_soldier_halo4",           "74a9e4ce-0d3e-4716-96e3-c53021f494e5"),
]

# Tilesets (top-down, sidescroller, etc.)
TILESETS = [
    ("topdown", "5302d681-5ba0-4528-89a2-526422d9d170"),  # alien planet + moon terrain
]

CHAR_URL = "https://api.pixellab.ai/mcp/characters/{id}/download"
TILESET_URL = "https://api.pixellab.ai/mcp/tilesets/topdown/{id}/download"

ok_chars = []
fail_chars = []
ok_tiles = []
fail_tiles = []

# Download characters
for name, cid in CHARACTERS:
    url = CHAR_URL.format(id=cid)
    dest = os.path.join(BACKUP_DIR, "characters", f"{name}_{cid[:8]}.zip")

    if os.path.exists(dest) and os.path.getsize(dest) > 1024:
        print(f"  [SKIP]  {name}  (already exists)")
        ok_chars.append(name)
        continue

    print(f"  [DL]    {name} ...", end=" ", flush=True)
    result = subprocess.run(
        ["curl", "--fail", "--silent", "--location", "-o", dest, url],
        capture_output=True,
    )

    if result.returncode != 0 or not os.path.exists(dest) or os.path.getsize(dest) < 1024:
        print("FAILED")
        if os.path.exists(dest):
            os.remove(dest)
        fail_chars.append(name)
    else:
        size_kb = os.path.getsize(dest) // 1024
        print(f"OK  ({size_kb} KB)")
        ok_chars.append(name)

# Download tilesets
print("\n=== TILESETS ===")
for name, tid in TILESETS:
    url = TILESET_URL.format(id=tid)
    dest = os.path.join(BACKUP_DIR, "tilesets", f"{name}_{tid[:8]}.zip")

    if os.path.exists(dest) and os.path.getsize(dest) > 1024:
        print(f"  [SKIP]  {name}  (already exists)")
        ok_tiles.append(name)
        continue

    print(f"  [DL]    {name} ...", end=" ", flush=True)
    result = subprocess.run(
        ["curl", "--fail", "--silent", "--location", "-o", dest, url],
        capture_output=True,
    )

    if result.returncode != 0 or not os.path.exists(dest) or os.path.getsize(dest) < 1024:
        print("FAILED")
        if os.path.exists(dest):
            os.remove(dest)
        fail_tiles.append(name)
    else:
        size_kb = os.path.getsize(dest) // 1024
        print(f"OK  ({size_kb} KB)")
        ok_tiles.append(name)

print()
print(f"CHARACTERS: {len(ok_chars)} downloaded / skipped,  {len(fail_chars)} failed.")
print(f"TILESETS:  {len(ok_tiles)} downloaded / skipped,  {len(fail_tiles)} failed.")
if fail_chars:
    print("Failed chars:", ", ".join(fail_chars))
if fail_tiles:
    print("Failed tilesets:", ", ".join(fail_tiles))
