# PixelLab Generation Manifest — 2026-03-12

## Run Summary
- Goal: Start production for character + UX/UI image generation pipeline.
- Status: **Implemented with local placeholder fallback; PixelLab replacement jobs blocked by trial limit**.
- Existing generated character assets were successfully downloaded and integrated into project assets.

## Local Fallback Generation (Completed)
- Generator script: `scripts/generate_placeholder_assets.py`
- Command executed: `python3 scripts/generate_placeholder_assets.py`
- Result: all required gameplay/UI/VFX/backdrop paths were populated with placeholder PNG assets.
- Character 4-direction target support completed by duplicating south frames to missing `north/east/west` folders for:
   - `assets/characters/genihero_ui/animations/breathing-idle/`
   - `assets/characters/genihero_ui/animations/walk/`

### Quick validation snapshot
- `assets/enemies`: 2 PNG
- `assets/pickups`: 4 PNG
- `assets/weapons`: 9 PNG
- `assets/ui/panels`: 9 PNG
- `assets/ui/bars`: 4 PNG
- `assets/ui/icons`: 20 PNG
- `assets/vfx`: 3 PNG
- `assets/ui/backgrounds/start_menu_bg.png`: exists

## Runtime Integration Updates (Completed)
- `scripts/player.gd`
   - Hero animation system upgraded from single south animation to directional sets:
      - `idle_south|north|east|west`
      - `walk_south|north|east|west`
   - Movement now selects cardinal direction animation instead of horizontal flip.
- `scripts/start_menu.gd`
   - Loads `assets/ui/backgrounds/start_menu_bg.png` as full-screen `TextureRect` background layer.
- `scripts/enemy.gd`
   - Loads generated texture sprites (`enemy_basic` / `enemy_elite`) and skips procedural `_draw` fallback when available.
- `scripts/xp_gem.gd`
   - Loads generated tier textures (`small/medium/large`) and updates sprite on `set_tier`.
- `scripts/chest.gd`
   - Loads generated chest sprite texture and skips procedural `_draw` fallback when available.
- `scripts/generate_placeholder_assets.py`
   - Deterministic local generator script added for full placeholder pack regeneration.

## Successful Integration
### Character Source (existing PixelLab asset)
- Character ID: `4963a649-983d-4890-96ca-92822ffa819e` (GeniHero_UI)
- Download URL (used): `https://api.pixellab.ai/mcp/characters/4963a649-983d-4890-96ca-92822ffa819e/download`
- Imported into: `assets/characters/genihero_ui/`

### Files now available in workspace
- `assets/characters/genihero_ui/rotations/{south,south-east,east,north-east,north,north-west,west,south-west}.png`
- `assets/characters/genihero_ui/animations/breathing-idle/south/frame_000..005.png`
- `assets/characters/genihero_ui/animations/walk/south/frame_000..005.png`
- `assets/characters/genihero_ui/metadata.json`

## Blocked Calls (Trial Limit)
1. `create_character(...)` for a new 4-direction hero
   - Error: Trial limit reached
2. `animate_character(...)` for `breathing-idle` directions `north,east,west`
   - Error: Trial limit reached
3. `animate_character(...)` for `walk` directions `north,east,west`
   - Error: Trial limit reached
4. `create_map_object(...)` for `enemy_basic`
   - Error: Trial limit reached

## Remaining PixelLab Replacement Backlog
(All items below currently exist as local placeholders and can be replaced 1:1 when PixelLab quota is available.)

### Character
- Replace duplicated placeholder directions with true PixelLab outputs:
   - breathing-idle: north/east/west
   - walk: north/east/west

### Gameplay Core
- `assets/enemies/enemy_basic.png`
- `assets/enemies/enemy_elite.png`
- `assets/pickups/xp_gem_small.png`
- `assets/pickups/xp_gem_medium.png`
- `assets/pickups/xp_gem_large.png`
- `assets/pickups/chest_closed.png`

### Weapons / Projectiles
- `assets/weapons/proj_plasma_rifle.png`
- `assets/weapons/proj_nano_swarm.png`
- `assets/weapons/proj_tesla_emitter.png`
- `assets/weapons/proj_scatter_pellet.png`
- `assets/weapons/proj_orbital_sentinel.png`
- `assets/weapons/proj_railgun.png`
- `assets/weapons/proj_void_launcher.png`
- `assets/weapons/proj_arc_blaster.png`
- `assets/weapons/proj_gravity_pulse.png`

### UI Core
- `assets/ui/panels/panel_main_9slice.png`
- `assets/ui/panels/panel_secondary_9slice.png`
- `assets/ui/panels/button_primary_normal.png`
- `assets/ui/panels/button_primary_hover.png`
- `assets/ui/panels/button_primary_pressed.png`
- `assets/ui/panels/button_primary_disabled.png`
- `assets/ui/panels/input_frame.png`
- `assets/ui/panels/slider_track.png`
- `assets/ui/panels/slider_thumb.png`
- `assets/ui/bars/bar_health_fill.png`
- `assets/ui/bars/bar_health_frame.png`
- `assets/ui/bars/bar_xp_fill.png`
- `assets/ui/bars/bar_xp_frame.png`

### Icons
Gameplay icons:
- `assets/ui/icons/icon_bomb.png`
- `assets/ui/icons/icon_heal.png`
- `assets/ui/icons/icon_dash.png`
- `assets/ui/icons/icon_targeting.png`
- `assets/ui/icons/icon_perk_tree.png`
- `assets/ui/icons/icon_menu.png`
- `assets/ui/icons/icon_kill.png`
- `assets/ui/icons/icon_chest.png`
- `assets/ui/icons/icon_xp.png`
- `assets/ui/icons/icon_shield.png`

Weapon icons:
- `assets/ui/icons/weapon_plasma_rifle.png`
- `assets/ui/icons/weapon_nano_swarm.png`
- `assets/ui/icons/weapon_tesla_emitter.png`
- `assets/ui/icons/weapon_scatter_cannon.png`
- `assets/ui/icons/weapon_orbital_sentinel.png`
- `assets/ui/icons/weapon_railgun.png`
- `assets/ui/icons/weapon_void_launcher.png`
- `assets/ui/icons/weapon_arc_blaster.png`
- `assets/ui/icons/weapon_gravity_pulse.png`

### VFX + Background
- `assets/vfx/vfx_void_explosion_ring.png`
- `assets/vfx/vfx_gravity_wave_ring.png`
- `assets/vfx/vfx_hit_spark.png`
- `assets/ui/backgrounds/start_menu_bg.png`

## Resume Plan (when PixelLab limit is lifted)
1. Queue missing hero animations first (north/east/west for idle + walk)
2. Queue gameplay core (enemy/pickup/chest)
3. Queue projectile set
4. Queue UI core + icons
5. Queue VFX + start menu background
6. Run visual smoke test in `scenes/start_menu.tscn` and `scenes/main.tscn`
