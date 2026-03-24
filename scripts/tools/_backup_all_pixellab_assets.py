"""
Downloads ALL PixelLab assets (characters, tiles pro, tilesets) into assets/backup/
organized by type.
"""

import os
import subprocess
import json

BACKUP_DIR = os.path.join(os.path.dirname(__file__), "../../assets/backup")
os.makedirs(BACKUP_DIR, exist_ok=True)
os.makedirs(os.path.join(BACKUP_DIR, "tiles_pro"), exist_ok=True)
os.makedirs(os.path.join(BACKUP_DIR, "topdown_tilesets"), exist_ok=True)

# ==================== CHARACTERS ====================
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

# ==================== TILES PRO ====================
TILES_PRO = [
    ("toxic_nuclear_waste",           "aba397fd-6271-4555-b9f4-883769109dc3"),
    ("toxic_waste_bubbles",           "5ffa1d68-e7ab-4e18-9dab-97a5c6e3d2c8"),
    ("deep_water_floor",              "beb68381-d537-43c9-9bbc-3113c77ab0d9"),
    ("molten_lava_floor",             "512ab47c-ebca-4d18-bea2-74ef1ca121bf"),
    ("dark_forest_floor",             "9101fbae-5ee6-4514-90f5-6dbfc4ecdc07"),
    ("dark_stone_dungeon",            "7821b277-783c-42be-852e-c39a7ade3c8c"),
    ("dark_stone_floor_minimal",      "7061dab1-b7ce-4899-b4ed-cc65525ec025"),
    ("futuristic_input_frame_128_v1", "5e4f622d-a784-4f77-a164-fe2939c11206"),
    ("futuristic_input_frame_128_v2", "bece72f9-6a6d-4b01-81b5-b73f434eb447"),
    ("futuristic_main_ui_panel",      "8cb15da8-735f-4ff1-a24c-e7df938de1d1"),
    ("game_health_bar_fill",          "33e9f038-f2eb-4c75-b1e2-79087ae11073"),
    ("plasma_rifle_weapon_icon",      "ce71f485-c423-4aa2-9338-28c9d210d03d"),
    ("bomb_health_icons",             "d309e357-41de-4f09-be97-2ecd5e250353"),
]

# ==================== TILESETS ====================
TOPDOWN_TILESETS = [
    ("stone_to_metal",                "b188937e-3158-4b4b-a431-52b8056b8145"),
    ("alien_planet_moon",             "5302d681-5ba0-4528-89a2-526422d9d170"),
]

# URLs (note: uses hyphens, not underscores)
CHAR_URL = "https://api.pixellab.ai/mcp/characters/{id}/download"
TILES_PRO_URL = "https://api.pixellab.ai/mcp/tiles-pro/{id}/download"
TILESET_PNG_URL = "https://api.pixellab.ai/mcp/tilesets/{id}/image"
TILESET_META_URL = "https://api.pixellab.ai/mcp/tilesets/{id}/metadata"

stats = {"ok": 0, "skip": 0, "fail": 0}

def download(name, url, dest):
    """Download with error handling"""
    if os.path.exists(dest) and os.path.getsize(dest) > 1024:
        print(f"  [SKIP]  {name}")
        stats["skip"] += 1
        return True
    
    print(f"  [DL]    {name} ...", end=" ", flush=True)
    result = subprocess.run(
        ["curl", "--fail", "--silent", "--location", "-o", dest, url],
        capture_output=True,
        timeout=60,
    )
    
    if result.returncode != 0 or not os.path.exists(dest) or os.path.getsize(dest) < 1024:
        print("FAILED")
        if os.path.exists(dest):
            os.remove(dest)
        stats["fail"] += 1
        return False
    
    size_mb = os.path.getsize(dest) / (1024*1024)
    print(f"OK ({size_mb:.1f} MB)" if size_mb > 1 else f"OK ({os.path.getsize(dest)//1024} KB)")
    stats["ok"] += 1
    return True

# Download characters
print("=== CHARACTERS (18) ===")
for name, cid in CHARACTERS:
    url = CHAR_URL.format(id=cid)
    dest = os.path.join(BACKUP_DIR, f"{name}_{cid[:8]}.zip")
    download(name, url, dest)

# Download tiles pro
print("\n=== TILES PRO (13) ===")
for name, tid in TILES_PRO:
    url = TILES_PRO_URL.format(id=tid)
    dest = os.path.join(BACKUP_DIR, "tiles_pro", f"{name}_{tid[:8]}.zip")
    download(name, url, dest)

# Download topdown tilesets (PNG + metadata JSON)
print("\n=== TOPDOWN TILESETS (2) ===")
for name, tsid in TOPDOWN_TILESETS:
    # Download PNG
    png_url = TILESET_PNG_URL.format(id=tsid)
    png_dest = os.path.join(BACKUP_DIR, "topdown_tilesets", f"{name}_{tsid[:8]}.png")
    download(f"{name} (image)", png_url, png_dest)
    
    # Download metadata JSON
    meta_url = TILESET_META_URL.format(id=tsid)
    meta_dest = os.path.join(BACKUP_DIR, "topdown_tilesets", f"{name}_{tsid[:8]}.metadata.json")
    download(f"{name} (metadata)", meta_url, meta_dest)

# Summary
print("\n" + "="*50)
print(f"DONE: {stats['ok']} downloaded, {stats['skip']} skipped, {stats['fail']} failed")
print(f"Total: {stats['ok'] + stats['skip']} assets backed up")
print(f"Size: {os.popen(f'du -sh {BACKUP_DIR}').read().split()[0]}")
