# GeniHero Item & PNG Master List

Updated: 2026-03-15

Bu dosya, oyundaki tüm önemli item/kategori listelerini ve planlama için tam PNG envanterini içerir.

## 1) Quick Summary

- Toplam PNG: **120** (`assets/**` altında)
- PNG ama `.import` olmayan: **8**
- Kodda referanslanan ama dosyası olmayan gerçek PNG: **6**
- Upgrade/Perk kataloğu: **41** perk
- Silah tanımı (config): **10** weapon id

## 2) Gameplay Item Lists

### 2.1 Weapons (Config Definitions)

- `plasma_rifle`
- `nano_swarm`
- `tesla_emitter`
- `scatter_cannon`
- `orbital_sentinel`
- `railgun`
- `void_launcher`
- `arc_blaster`
- `phase_disruptor`
- `gravity_pulse`

### 2.2 Passive Weapons

- `plasma_rifle`
- `nano_swarm`
- `tesla_emitter`
- `scatter_cannon`
- `orbital_sentinel`

### 2.3 Active/Held Weapons (slots)

- Slot 1: `railgun`
- Slot 2: `void_launcher`
- Slot 3: `arc_blaster`
- Slot 4: `phase_disruptor`
- Slot 5: `gravity_pulse`

### 2.4 Projectile Classes

- `standard`
- `aoe`
- `bouncing`
- `beam`

### 2.5 Targeting Modes

- `forward`
- `rear_guard`
- `side_sweep`
- `full_spread`
- `orbital_fire`

### 2.6 Chest Rewards (GameManager)

- `heal`
- `shield`
- `magnet`
- `bomb`
- `perk_points`

### 2.7 HUD Notifications (explicit messages)

- `❤ +%d Can!`
- `🛡 Kalkan Aktif!`
- `🧲 Mıknatıs!`
- `💣 +1 Bomba!`
- `⭐ +%d Perk Puanı!`

## 3) Skills / Perks / Perk Tree List

Perk tree kategorileri (`perk_tree.gd`):

- Temel İstatistikler
- Gelişmiş Yetenekler
- İleri Seviye
- Uzmanlık
- Pasif Silahlar
- Pasif Güçlendirme
- Aktif Silahlar
- Aktif Güçlendirme

Upgrade katalogu (`game_manager.gd`) — id | görünen ad:

- `attack_speed` | Saldırı Hızı
- `weapon_damage` | Saldırı Değeri
- `max_health` | Maksimum Can
- `move_speed` | Hız
- `crit_chance` | Kritik Şansı
- `cooldown_mastery` | Sistem Optimizasyonu
- `weapon_projectile` | Ammo Adedi
- `life_regen` | Can Yenileme
- `dash` | Faz Kayması
- `xp_magnet` | Toplama Alanı
- `pierce` | Delici Mermi
- `burn_dot` | Yakıcı Atış
- `rear_targeting` | Arka Nişan
- `side_sweep` | Yan Tarama
- `armor` | Savunma Değeri
- `xp_multiplier` | XP Verimi
- `unlock_nano` | Nano Swarm
- `unlock_tesla` | Tesla Emitter
- `unlock_scatter` | Scatter Cannon
- `unlock_bouncing_projectile` | Sekebilen Mermi
- `unlock_aoe_projectile` | Patlayıcı Mermi
- `unlock_beam_projectile` | Işın Mermi
- `full_spread` | Tam Yelpaze
- `orbital_fire` | Orbital Ateş
- `shield` | Enerji Kalkanı
- `luck` | Şans
- `unlock_orbital_sentinel` | Orbital Sentinel
- `upgrade_nano` | Nano Güçlendirme
- `upgrade_tesla` | Tesla Güçlendirme
- `upgrade_scatter` | Scatter Güçlendirme
- `upgrade_orbital` | Orbital Güçlendirme
- `unlock_railgun` | Railgun
- `unlock_void` | Void Launcher
- `unlock_arc` | Arc Blaster
- `unlock_phase` | Phase Disruptor
- `unlock_gravity` | Gravity Pulse
- `upgrade_railgun` | Railgun Güçlendirme
- `upgrade_void` | Void Güçlendirme
- `upgrade_arc` | Arc Güçlendirme
- `upgrade_phase` | Phase Güçlendirme
- `upgrade_gravity` | Gravity Güçlendirme

## 4) Character Items

### 4.1 Character Rotations (8)

- `assets/characters/genihero_ui/rotations/east.png`
- `assets/characters/genihero_ui/rotations/north-east.png`
- `assets/characters/genihero_ui/rotations/north-west.png`
- `assets/characters/genihero_ui/rotations/north.png`
- `assets/characters/genihero_ui/rotations/south-east.png`
- `assets/characters/genihero_ui/rotations/south-west.png`
- `assets/characters/genihero_ui/rotations/south.png`
- `assets/characters/genihero_ui/rotations/west.png`

### 4.2 Character Animation Sets

- breathing-idle: `north`, `south`, `east`, `west` x 6 frame
- walk: `north`, `south`, `east`, `west` x 6 frame

Toplam ana karakter animasyon frame PNG: **48**

## 5) UI Item Lists

### 5.1 UI Icons

- `icon_bomb`
- `icon_chest`
- `icon_dash`
- `icon_heal`
- `icon_kill`
- `icon_menu`
- `icon_perk_tree`
- `icon_player_hero`
- `icon_shield`
- `icon_targeting`
- `icon_xp`
- `weapon_arc_blaster`
- `weapon_gravity_pulse`
- `weapon_nano_swarm`
- `weapon_orbital_sentinel`
- `weapon_plasma_rifle`
- `weapon_railgun`
- `weapon_scatter_cannon`
- `weapon_tesla_emitter`
- `weapon_void_launcher`

### 5.2 UI Bars

- `bar_health_fill`
- `bar_health_frame`
- `bar_xp_fill`
- `bar_xp_frame`

### 5.3 UI Panels

- `button_primary_disabled`
- `button_primary_hover`
- `button_primary_normal`
- `button_primary_pressed`
- `input_frame`
- `panel_main_9slice`
- `panel_secondary_9slice`
- `slider_thumb`
- `slider_track`

### 5.4 UI Backgrounds

- `start_menu_bg`
- Character preview idle_south (6 frame)
- Character preview walk_south (6 frame)

## 6) Full PNG Path List (Master)

```txt
assets/characters/genihero_ui/animations/breathing-idle/east/frame_000.png
assets/characters/genihero_ui/animations/breathing-idle/east/frame_001.png
assets/characters/genihero_ui/animations/breathing-idle/east/frame_002.png
assets/characters/genihero_ui/animations/breathing-idle/east/frame_003.png
assets/characters/genihero_ui/animations/breathing-idle/east/frame_004.png
assets/characters/genihero_ui/animations/breathing-idle/east/frame_005.png
assets/characters/genihero_ui/animations/breathing-idle/north/frame_000.png
assets/characters/genihero_ui/animations/breathing-idle/north/frame_001.png
assets/characters/genihero_ui/animations/breathing-idle/north/frame_002.png
assets/characters/genihero_ui/animations/breathing-idle/north/frame_003.png
assets/characters/genihero_ui/animations/breathing-idle/north/frame_004.png
assets/characters/genihero_ui/animations/breathing-idle/north/frame_005.png
assets/characters/genihero_ui/animations/breathing-idle/south/frame_000.png
assets/characters/genihero_ui/animations/breathing-idle/south/frame_001.png
assets/characters/genihero_ui/animations/breathing-idle/south/frame_002.png
assets/characters/genihero_ui/animations/breathing-idle/south/frame_003.png
assets/characters/genihero_ui/animations/breathing-idle/south/frame_004.png
assets/characters/genihero_ui/animations/breathing-idle/south/frame_005.png
assets/characters/genihero_ui/animations/breathing-idle/west/frame_000.png
assets/characters/genihero_ui/animations/breathing-idle/west/frame_001.png
assets/characters/genihero_ui/animations/breathing-idle/west/frame_002.png
assets/characters/genihero_ui/animations/breathing-idle/west/frame_003.png
assets/characters/genihero_ui/animations/breathing-idle/west/frame_004.png
assets/characters/genihero_ui/animations/breathing-idle/west/frame_005.png
assets/characters/genihero_ui/animations/walk/east/frame_000.png
assets/characters/genihero_ui/animations/walk/east/frame_001.png
assets/characters/genihero_ui/animations/walk/east/frame_002.png
assets/characters/genihero_ui/animations/walk/east/frame_003.png
assets/characters/genihero_ui/animations/walk/east/frame_004.png
assets/characters/genihero_ui/animations/walk/east/frame_005.png
assets/characters/genihero_ui/animations/walk/north/frame_000.png
assets/characters/genihero_ui/animations/walk/north/frame_001.png
assets/characters/genihero_ui/animations/walk/north/frame_002.png
assets/characters/genihero_ui/animations/walk/north/frame_003.png
assets/characters/genihero_ui/animations/walk/north/frame_004.png
assets/characters/genihero_ui/animations/walk/north/frame_005.png
assets/characters/genihero_ui/animations/walk/south/frame_000.png
assets/characters/genihero_ui/animations/walk/south/frame_001.png
assets/characters/genihero_ui/animations/walk/south/frame_002.png
assets/characters/genihero_ui/animations/walk/south/frame_003.png
assets/characters/genihero_ui/animations/walk/south/frame_004.png
assets/characters/genihero_ui/animations/walk/south/frame_005.png
assets/characters/genihero_ui/animations/walk/west/frame_000.png
assets/characters/genihero_ui/animations/walk/west/frame_001.png
assets/characters/genihero_ui/animations/walk/west/frame_002.png
assets/characters/genihero_ui/animations/walk/west/frame_003.png
assets/characters/genihero_ui/animations/walk/west/frame_004.png
assets/characters/genihero_ui/animations/walk/west/frame_005.png
assets/characters/genihero_ui/rotations/east.png
assets/characters/genihero_ui/rotations/north-east.png
assets/characters/genihero_ui/rotations/north-west.png
assets/characters/genihero_ui/rotations/north.png
assets/characters/genihero_ui/rotations/south-east.png
assets/characters/genihero_ui/rotations/south-west.png
assets/characters/genihero_ui/rotations/south.png
assets/characters/genihero_ui/rotations/west.png
assets/enemies/enemy_basic.png
assets/enemies/enemy_elite.png
assets/pickups/chest_closed.png
assets/pickups/xp_gem_large.png
assets/pickups/xp_gem_medium.png
assets/pickups/xp_gem_small.png
assets/ui/backgrounds/character_previews/idle_south/frame_000.png
assets/ui/backgrounds/character_previews/idle_south/frame_001.png
assets/ui/backgrounds/character_previews/idle_south/frame_002.png
assets/ui/backgrounds/character_previews/idle_south/frame_003.png
assets/ui/backgrounds/character_previews/idle_south/frame_004.png
assets/ui/backgrounds/character_previews/idle_south/frame_005.png
assets/ui/backgrounds/character_previews/walk_south/frame_000.png
assets/ui/backgrounds/character_previews/walk_south/frame_001.png
assets/ui/backgrounds/character_previews/walk_south/frame_002.png
assets/ui/backgrounds/character_previews/walk_south/frame_003.png
assets/ui/backgrounds/character_previews/walk_south/frame_004.png
assets/ui/backgrounds/character_previews/walk_south/frame_005.png
assets/ui/backgrounds/start_menu_bg.png
assets/ui/bars/bar_health_fill.png
assets/ui/bars/bar_health_frame.png
assets/ui/bars/bar_xp_fill.png
assets/ui/bars/bar_xp_frame.png
assets/ui/icons/icon_bomb.png
assets/ui/icons/icon_chest.png
assets/ui/icons/icon_dash.png
assets/ui/icons/icon_heal.png
assets/ui/icons/icon_kill.png
assets/ui/icons/icon_menu.png
assets/ui/icons/icon_perk_tree.png
assets/ui/icons/icon_player_hero.png
assets/ui/icons/icon_shield.png
assets/ui/icons/icon_targeting.png
assets/ui/icons/icon_xp.png
assets/ui/icons/weapon_arc_blaster.png
assets/ui/icons/weapon_gravity_pulse.png
assets/ui/icons/weapon_nano_swarm.png
assets/ui/icons/weapon_orbital_sentinel.png
assets/ui/icons/weapon_plasma_rifle.png
assets/ui/icons/weapon_railgun.png
assets/ui/icons/weapon_scatter_cannon.png
assets/ui/icons/weapon_tesla_emitter.png
assets/ui/icons/weapon_void_launcher.png
assets/ui/panels/button_primary_disabled.png
assets/ui/panels/button_primary_hover.png
assets/ui/panels/button_primary_normal.png
assets/ui/panels/button_primary_pressed.png
assets/ui/panels/input_frame.png
assets/ui/panels/panel_main_9slice.png
assets/ui/panels/panel_secondary_9slice.png
assets/ui/panels/slider_thumb.png
assets/ui/panels/slider_track.png
assets/vfx/vfx_gravity_wave_ring.png
assets/vfx/vfx_hit_spark.png
assets/vfx/vfx_void_explosion_ring.png
assets/weapons/proj_arc_blaster.png
assets/weapons/proj_gravity_pulse.png
assets/weapons/proj_nano_swarm.png
assets/weapons/proj_orbital_sentinel.png
assets/weapons/proj_plasma_rifle.png
assets/weapons/proj_railgun.png
assets/weapons/proj_scatter_pellet.png
assets/weapons/proj_tesla_emitter.png
assets/weapons/proj_void_launcher.png
```

## 7) PNG Import / Reference Audit

### 7.1 PNG var ama `.import` yok

- `assets/ui/icons/icon_bomb.png`
- `assets/ui/icons/icon_dash.png`
- `assets/ui/icons/icon_heal.png`
- `assets/ui/icons/icon_shield.png`
- `assets/ui/icons/icon_targeting.png`
- `assets/ui/icons/weapon_plasma_rifle.png`
- `assets/ui/icons/weapon_railgun.png`
- `assets/ui/icons/weapon_void_launcher.png`

### 7.2 Kodda referans var ama PNG dosyası yok (gerçek path)

- `assets/ui/backgrounds/hero_platform_glow.png`
- `assets/ui/panels/button_secondary_hover.png`
- `assets/ui/panels/button_secondary_normal.png`
- `assets/ui/panels/button_secondary_pressed.png`
- `assets/ui/panels/button_utility_hover.png`
- `assets/ui/panels/button_utility_normal.png`

### 7.3 Template path’ler (dinamik oluşturulan; fiziksel dosya adı değil)

- `assets/weapons/proj_%s.png`
- `assets/weapons/held_%s.png`
- `assets/ui/icons/weapon_%s.png`
- `assets/characters/genihero_ui/animations/%s/%s/frame_%03d.png`
- `assets/characters/genihero_ui/animations/%s/south/frame_%03d.png`
- `assets/ui/backgrounds/character_previews/idle_south/frame_%03d.png`
- `assets/ui/backgrounds/character_previews/walk_south/frame_%03d.png`

---

Not: Bu dosya planlama checklist’i içindir; üretim sırasında yeni PNG eklendikçe güncellenmelidir.
