# AI Asset Prompt Pack — Protocol: Hex0

Bu dosya, `ART_DIRECTION_UI_CHARACTER.md` içindeki kurallara göre doğrudan görsel üretim için hazırlanmıştır.

## Global Prompt (her promptun başına ekle)

`2D top-down sci-fi action game asset, stylized but highly readable, clean silhouette, medium detail, soft neon accents, transparent background, no text, production-ready game sprite`

## Negative Prompt (her promptun sonuna ekle)

`photorealistic, noisy background, watermark, logo, text, blurry edges, low contrast, over-detailed tiny elements`

---

## A) Characters

### 1) Hero Base
- Output: `assets/characters/hero_base.png`
- Prompt:
`top-down hero character, compact readable silhouette, cyan energy core on chest, dark metallic armor, white energy accents, action-ready neutral stance`

### 2) Hero Hit Overlay
- Output: `assets/characters/hero_hit_overlay.png`
- Prompt:
`top-down hero damage flash overlay, bright white-cyan energy crack effect, additive style, no background`

---

## B) Enemies

### 1) Enemy Basic
- Output: `assets/enemies/enemy_basic.png`
- Prompt:
`top-down enemy unit, aggressive silhouette, red primary color, simple readable shape for fast combat`

### 2) Enemy Elite
- Output: `assets/enemies/enemy_elite.png`
- Prompt:
`top-down elite enemy variant, larger mass and armored look, magenta glow accents, higher threat hierarchy than basic enemy`

---

## C) Pickups

### 1) XP Small
- Output: `assets/pickups/xp_gem_small.png`
- Prompt:
`small energy crystal pickup, green glow, top-down, clean edges`

### 2) XP Medium
- Output: `assets/pickups/xp_gem_medium.png`
- Prompt:
`medium energy crystal pickup, blue glow, same family as small xp crystal`

### 3) XP Large
- Output: `assets/pickups/xp_gem_large.png`
- Prompt:
`large energy crystal pickup, golden glow, premium reward look, same family style`

### 4) Chest
- Output: `assets/pickups/chest_closed.png`
- Prompt:
`top-down sci-fi loot chest, dark body with gold accents, compact readable game prop`

---

## D) Weapon Projectiles

### 1) Plasma
- Output: `assets/weapons/proj_plasma_rifle.png`
- Prompt: `small plasma bolt projectile, cyan-blue energy trail`

### 2) Nano
- Output: `assets/weapons/proj_nano_swarm.png`
- Prompt: `tiny fast nano projectile, green-cyan luminous particle look`

### 3) Tesla
- Output: `assets/weapons/proj_tesla_emitter.png`
- Prompt: `electric projectile core, light blue electricity arcs`

### 4) Scatter
- Output: `assets/weapons/proj_scatter_pellet.png`
- Prompt: `short-range pellet projectile, orange kinetic spark look`

### 5) Orbital
- Output: `assets/weapons/proj_orbital_sentinel.png`
- Prompt: `golden energy orb projectile, stable circular core glow`

### 6) Railgun
- Output: `assets/weapons/proj_railgun.png`
- Prompt: `high-speed rail slug or thin red beam bolt, piercing visual language`

### 7) Void
- Output: `assets/weapons/proj_void_launcher.png`
- Prompt: `dark-purple void orb projectile, dense center and subtle distortion glow`

### 8) Arc Blaster
- Output: `assets/weapons/proj_arc_blaster.png`
- Prompt: `electric arc projectile, blue-white jagged energy motif`

### 9) Gravity Pulse
- Output: `assets/weapons/proj_gravity_pulse.png`
- Prompt: `blue gravity pulse core, compressed energy sphere look`

### 10) Phase Disruptor (optional)
- Output: `assets/weapons/proj_phase_disruptor.png`
- Prompt: `violet phase wave core projectile, void-tech visual style`

---

## E) VFX

### 1) Void Explosion Ring
- Output: `assets/vfx/vfx_void_explosion_ring.png`
- Prompt: `purple-black circular energy explosion ring, transparent center, stylized`

### 2) Gravity Wave Ring
- Output: `assets/vfx/vfx_gravity_wave_ring.png`
- Prompt: `blue concentric gravity shockwave ring, clean readable effect`

### 3) Generic Hit Spark
- Output: `assets/vfx/vfx_hit_spark.png`
- Prompt: `compact hit spark for top-down combat, orange-white impact burst`

---

## F) UI Panels / Core Components

### 1) Main Panel (9-slice)
- Output: `assets/ui/panels/panel_main_9slice.png`
- Prompt:
`futuristic dark blue-gray ui panel frame, subtle neon edge highlights, 9-slice friendly corners and borders`

### 2) Secondary Panel (9-slice)
- Output: `assets/ui/panels/panel_secondary_9slice.png`
- Prompt:
`minimal futuristic secondary panel frame, lower emphasis than main panel, 9-slice friendly`

### 3) Button States
- Output:
  - `assets/ui/panels/button_primary_normal.png`
  - `assets/ui/panels/button_primary_hover.png`
  - `assets/ui/panels/button_primary_pressed.png`
  - `assets/ui/panels/button_primary_disabled.png`
- Prompt:
`futuristic rectangular game ui button, high readability, consistent style across normal hover pressed disabled states`

### 4) Input Frame
- Output: `assets/ui/panels/input_frame.png`
- Prompt: `futuristic line input frame, dark interior, clear border contrast`

### 5) Slider
- Output:
  - `assets/ui/panels/slider_track.png`
  - `assets/ui/panels/slider_thumb.png`
- Prompt:
`sci-fi ui slider component, clean track and distinct thumb for quick interaction visibility`

### 6) Modal Backdrop Texture (optional)
- Output: `assets/ui/backgrounds/modal_backdrop_noise.png`
- Prompt: `very subtle dark gradient-noise texture for modal backdrop overlay`

---

## G) UI Bars

### 1) Health Bar
- Output:
  - `assets/ui/bars/bar_health_fill.png`
  - `assets/ui/bars/bar_health_frame.png`
- Prompt:
`game health bar fill and frame, red fill, clear sci-fi border`

### 2) XP Bar
- Output:
  - `assets/ui/bars/bar_xp_fill.png`
  - `assets/ui/bars/bar_xp_frame.png`
- Prompt:
`game xp bar fill and frame, cyan-blue fill, clean futuristic style`

---

## H) UI Icons (32x32 öneri)

- `assets/ui/icons/icon_bomb.png` → `minimal bomb icon, sci-fi style`
- `assets/ui/icons/icon_heal.png` → `minimal heal cross or med capsule icon, sci-fi style`
- `assets/ui/icons/icon_dash.png` → `motion streak dash icon`
- `assets/ui/icons/icon_targeting.png` → `reticle/targeting mode icon`
- `assets/ui/icons/icon_perk_tree.png` → `branching nodes perk icon`
- `assets/ui/icons/icon_menu.png` → `menu/settings icon`
- `assets/ui/icons/icon_kill.png` → `skull/kill marker icon`
- `assets/ui/icons/icon_chest.png` → `loot chest icon`
- `assets/ui/icons/icon_xp.png` → `xp crystal icon`
- `assets/ui/icons/icon_shield.png` → `shield armor icon`

---

## I) Weapon Icons

- `assets/ui/icons/weapon_plasma_rifle.png`
- `assets/ui/icons/weapon_nano_swarm.png`
- `assets/ui/icons/weapon_tesla_emitter.png`
- `assets/ui/icons/weapon_scatter_cannon.png`
- `assets/ui/icons/weapon_orbital_sentinel.png`
- `assets/ui/icons/weapon_railgun.png`
- `assets/ui/icons/weapon_void_launcher.png`
- `assets/ui/icons/weapon_arc_blaster.png`
- `assets/ui/icons/weapon_gravity_pulse.png`
- `assets/ui/icons/weapon_phase_disruptor.png` (opsiyonel)

Prompt kalıbı:
`top-down weapon icon for sci-fi action game, minimal readable silhouette, high contrast at small size, no text`

---

## J) Yeni UI Overhaul Assetleri

Bu bölüm, UI overhaul planı kapsamında gereken yeni assetleri tanımlar.

### 1) HUD Stats Background Panel (9-slice)
- Output: `assets/ui/panels/panel_hud_stats.png`
- Prompt:
`compact futuristic HUD stats panel background, very dark semi-transparent, subtle neon edge glow on top/left edges, 9-slice corners, game overlay style`
- Not: 64×64 minimum, `offset_right=290 offset_bottom=235` ile top-left yerleşimde kullanılacak

### 2) Hero Platform Glow
- Output: `assets/ui/backgrounds/hero_platform_glow.png`
- Prompt:
`elliptical sci-fi energy platform glow, cyan-teal color, soft radial fade to transparent, no sharp edges, top-down ambient light pool`
- Not: 128×32 önerilen, sprite altına yatay elips olarak yerleşecek, alpha ile karışacak

### 3) Secondary Button States
- Output:
  - `assets/ui/panels/button_secondary_normal.png`
  - `assets/ui/panels/button_secondary_hover.png`
  - `assets/ui/panels/button_secondary_pressed.png`
- Prompt:
`futuristic game ui secondary button, lower visual weight than primary, subtle border, dark background, consistent with primary button family but quieter`
- Not: `button_primary_*.png` ailesine görsel olarak bağlı kalmalı, daha az parlak

### 4) Utility Button States (HUD top-right)
- Output:
  - `assets/ui/panels/button_utility_normal.png`
  - `assets/ui/panels/button_utility_hover.png`
- Prompt:
`small futuristic HUD utility button, minimal style, dark semi-transparent background, thin tech border, for compact icon+label buttons in game overlay`
- Not: min 38px yükseklik, `Perks / Projectile / Menu` butonlarında kullanılacak

---

## Üretim Parametre Önerisi

- PNG, transparent background
- Icon: 32x32 (veya 64x64 downscale)
- Character/Enemy: 64x64 veya 96x96
- Projectile: 16x16 veya 32x32
- VFX Ring: 128x128 / 256x256
- Panel 9-slice: en az 64x64 border-safe
