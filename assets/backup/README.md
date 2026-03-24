# PixelLab Asset Backup

Tüm PixelLab tarafından üretilen assetlerin yedekleri bu klasörde saklanır.

## Yapı

```
backup/
  ├── *_*.zip                              # 18 Character ZIPler
  ├── tiles_pro/                           # 10 Tiles Pro (UI, icons, floor variations)
  │   └── *_*.zip
  ├── topdown_tilesets/                    # 2 Topdown Tileset (PNG + metadata JSON pairs)
  │   ├── stone_to_metal_b188937e.*
  │   └── alien_planet_moon_5302d681.*
  ├── tilesets/                            # Eski format (legacy)
  │   └── topdown_5302d681.zip
  └── README.md
```

## İçerik

### ✅ Characters (18 ZIP dosyası)
Her ZIP: character rotations (4 veya 8 yön) + tüm animasyonlar + collision keypoints

- bg_test_soldier (8 directions)
- GeniHero_Main_v2 (4 dir + 8 anims)
- GeniHero_UI (8 dir + 17 anims)
- GeniHero_CopperGolem_Main (4 dir + 2 anims)
- GeniHero_EnemyBasic (4 dir + 4 anims)
- GeniHero_EnemyElite (4 dir + 4 anims)
- enemy_skirmisher, enemy_runner, enemy_juggernaut, enemy_mortar
- enemy_sniper, enemy_suppressor, enemy_charger, enemy_shielded
- enemy_brute, enemy_zigzag (4 dir + 2 anims each)
- halo4_spaceman, super_soldier_halo4

### ✅ Tiles Pro (10 ZIP dosyası + 3 processing)
Individual tile variations 32×32 ve 64×64 px, square_topdown format

**Completed:**
- toxic_nuclear_waste (4 var)
- deep_water_floor (4 var)
- molten_lava_floor (4 var)
- dark_forest_floor (6 var)
- dark_stone_dungeon (6 var)
- dark_stone_floor_minimal (6 var)
- futuristic_main_ui_panel (9 var)
- game_health_bar_fill (4 var)
- plasma_rifle_weapon_icon (9 var)
- bomb_health_icons (10 var)

**Processing (retry later):**
- toxic_waste_bubbles
- futuristic_input_frame_128_v1
- futuristic_input_frame_128_v2

### ✅ Topdown Tilesets (2 sets, PNG + metadata JSON)
32×32 seamless Wang tileset format

- **stone_to_metal** - Dark stone → cracked metal plates (16 tiles)
- **alien_planet_moon** - Toxic alien planet → moon terrain (25 tiles)

## Dosya Boyutları

| Tip | Sayı | Toplam |
|-----|------|--------|
| Characters | 18 | ~1.2 MB |
| Tiles Pro | 10 | ~150 KB |
| Topdown Tilesets | 4 files (2 pairs) | ~30 KB |
| **TOTAL** | **32** | **1.4 MB** |

## Download & Restore Komutları

### Hepsini indir
```bash
cd /Users/berkay/Desktop/work/geni-hero
python3 scripts/tools/_backup_all_pixellab_assets.py
```

### Character restore
```bash
unzip -o assets/backup/GeniHero_Main_v2_*.zip -d assets/characters/
unzip -o assets/backup/enemy_*.zip -d assets/characters/
```

### Tiles Pro restore
```bash
unzip -o assets/backup/tiles_pro/*.zip -d assets/pickups/
```

### Topdown Tileset restore
```bash
cp assets/backup/topdown_tilesets/*.png assets/backgrounds/
cp assets/backup/topdown_tilesets/*.json assets/backgrounds/
```

## Not

- **Processing status**: Bazı tiles henüz processing'de. Script otomatik olarak retry'ler.
- **Legacy folder**: `tilesets/` klasörü eski format, yeni tilesets `topdown_tilesets/` içinde.
- **Character animations**: Tüm yönler (4 or 8) + walk, idle, attack animasyonları included.

## PixelLab Dokumentasyon

- https://pixellab.ai
- Character format: rotations/ + animations/
- Tiles Pro: individual PNG tiles
- Topdown Tilesets: Wang tiling system (metadata.json format)
