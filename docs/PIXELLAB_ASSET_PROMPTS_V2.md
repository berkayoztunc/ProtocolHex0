# PixelLab Asset Generation Prompts — V2
# Weapons, Projectiles, VFX, Icons (9-weapon system)
# Run each prompt via mcp_pixellab_create_map_object or the PixelLab dashboard

## Global Style
- **Base style**: 2D top-down sci-fi action game. Stylized pixel art, medium detail (~16-24px effective resolution upscaled to target size). Clean silhouette, strongly readable at small sizes.
- **Background**: Fully transparent (alpha 0)
- **No text, no watermark, no logo**
- **Negative prompt**: photorealistic, noisy background, watermark, text, blurry edges, low contrast, over-shading, 3D render, isometric, side-view characters

---

## GRUP A — Projectile Sprites

### A1 · `proj_rocket_blaster.png` · 32×32
**Prompt:**
Top-down 2D sci-fi game rocket projectile sprite. Elongated oval dark-red metallic body, pointed silver nosecone at the right tip, two small angular fins at the tail. Bright orange-yellow flame exhaust trail streaming leftward from the tail. Transparent background. Clean readable silhouette. No text.

**Style notes:** weapon projectile, kinetic feel, orange glow from exhaust has soft alpha fade

---

### A2 · `proj_octo_gun.png` · 24×12
**Prompt:**
Tiny 2D top-down game projectile sprite. Small copper-orange oval bullet shape, lighter copper highlight on top-left, slightly darker tail. Pointing right. Transparent background. Very small compact shape, clean edges, pixel art style.

**Style notes:** fast kinetic bullet, warm copper tones, hard edges

---

### A3 · `proj_blitz_bomb.png` · 32×32
**Prompt:**
2D top-down sci-fi cryo bomb projectile. Round icy sphere, translucent blue-white surface with crystalline ice texture, inner cyan glow. Small ice crystal spikes radiating outward at 6 evenly spaced points. Soft outer glow ring in pale cyan. Transparent background. Pixel art style.

**Style notes:** blitz/cryo weapon, cold blue palette, visible internal glow

---

### A4 · `proj_orbital_mayhem.png` · 28×32
**Prompt:**
2D top-down sci-fi rocket falling diagonally from top-right to bottom-left. Dark steel-grey metal body, silver reflective nosecone at bottom-right tip. Orange-red fire trail erupting from upper-left. Small dark-grey smoke puff behind the fire. Transparent background. Pixel art style.

**Style notes:** aerial bombardment rocket, falling at ~45 degrees, fire heavier than smoke

---

## GRUP B — VFX Effects

### B1 · `vfx_explosion_burst.png` · 96×96
**Prompt:**
2D top-down game explosion VFX sprite. Multi-ring circular burst. Outermost ring: faint orange heat shimmer. Second ring: bright orange-red flames. Inner ring: intense white-yellow core flash. Center fully transparent. Small bright debris particles scattered between rings. Transparent background. Pixel art VFX style.

**Style notes:** explosive bullet hit + rocket impact, layered alpha rings, no smoke (instant burst)

---

### B2 · `vfx_electric_arc.png` · 64×64
**Prompt:**
2D top-down electric chain lightning VFX sprite. Six jagged bright-blue lightning bolt branches radiating outward from a bright white center point. Each branch is irregular, roughly 2–3 segments with random angle offsets. Outer tips fade in alpha. Electric blue (#7DC8FF) with white inner core. Transparent background. Pixel art VFX style.

**Style notes:** electric chain effect between enemies, high contrast vs dark backgrounds

---

### B3 · `vfx_sonic_jump_flash.png` · 80×80
**Prompt:**
2D top-down teleport/dash origin flash VFX. Radial starburst in cyan-white. 16 thin streaks radiating from a bright white center, alternating long and short. Outer streaks fade to transparent cyan. Soft circular white core glow at center. Transparent background. Pixel art VFX style.

**Style notes:** sonic jumper skill teleport departure point, feels like a camera flash

---

### B4 · `vfx_sonic_jump_ring.png` · 96×96
**Prompt:**
2D top-down circular shockwave ring VFX. Thick hollow cyan ring, sharp inner edge, soft outer fade to transparent. Three concentric rings at decreasing opacity. Twelve small energy spike protrusions pointing outward from outermost ring. Center fully transparent. Bright cyan (#40E8FF) palette. Transparent background. Pixel art VFX style.

**Style notes:** sonic jumper skill landing AoE indicator/feedback ring

---

### B5 · `vfx_spin_laser_beam.png` · 256×8
**Prompt:**
2D game horizontal laser beam sprite, 256×8 pixels. Bright green neon beam. Center 2 pixels: near-white (#EEFFEE). Middle band: vivid green (#40FF60). Outer 1px at top and bottom: very soft low-opacity green glow. Left and right ends: fade to transparent. Transparent background. Pixel art style.

**Style notes:** spin laser rotating beam, seamlessly repeatable, no start/end caps

---

### B6 · `vfx_freeze_burst.png` · 96×96
**Prompt:**
2D top-down cryo freeze burst VFX. Circular frost explosion ring. Multiple concentric pale-cyan rings. Between rings: 12 pointed ice shard fragments radiating outward, each a thin elongated diamond shape in white-cyan. Center transparent. Cold blue-white palette (#A0E8FF, #DFFFFF). Transparent background. Pixel art VFX style.

**Style notes:** blitz bomb AoE freeze on impact, should feel cold and crystalline

---

### B7 · `vfx_magnetic_pulse.png` · 128×128
**Prompt:**
2D top-down magnetic field activation VFX. Five concentric expanding circles in teal-blue (#3CC8DC), decreasing opacity outward. Thin horizontal arc lines connecting left and right sides at regular vertical intervals (like field flux lines), very low opacity. Small glowing teal particle dot at center. Transparent background. Pixel art VFX style.

**Style notes:** magnetic field skill activation, calm expanding energy feel

---

### B8 · `vfx_rocket_smoke_trail.png` · 48×48
**Prompt:**
2D game smoke puff particle sprite. Soft irregular cloud of dark-grey to brown-grey smoke. 4–5 overlapping soft oval shapes at varying sizes and opacities to create a fluffy cloud silhouette. Edges very soft with alpha fade. Color: warm dark grey (#8C8278). Transparent background. Pixel art style.

**Style notes:** rocket flight smoke trail particle (spawned multiple times), very soft edges

---

### B9 · `vfx_orbital_streak.png` · 64×64
**Prompt:**
2D top-down diagonal falling rocket trail VFX. Top-left corner: small soft grey-brown smoke puff. Center-to-bottom-right: bright orange-yellow fire streak in an elongated narrow ellipse. Slight white-yellow highlight along the center of the fire streak. Bottom-right tip: small intense orange glow. Diagonal orientation ~45 degrees. Transparent background. Pixel art VFX style.

**Style notes:** orbital mayhem per-rocket trailing effect, spawned behind each falling rocket

---

### B10 · `vfx_world_bomb_indicator.png` · 96×96
**Prompt:**
2D top-down danger zone indicator ring VFX. Thick red warning ring (outer radius ~44px, inner transparent). Eight short thick red tick marks pointing inward at evenly spaced angles. Small exclamation mark symbol in center. All elements in bright danger red (#DC2828) with slight alpha variation for pulsing feel. Transparent background. Pixel art VFX style.

**Style notes:** world bomb countdown indicator, placed under bomb object on ground, should read as "danger zone"

---

## GRUP C — Weapon Icons (64×64)

> All icons: dark blue-grey rounded rectangle background (28, 38, 55), blue-white border (100, 140, 200), clear foreground symbol. Game HUD style.

### C1 · `weapon_rocket_blaster.png` · 64×64
**Prompt:**
2D sci-fi game HUD weapon icon. Dark panel. Small red rocket projectile with orange flame, pointed right. Five small red dots arranged in wide-spread V-pattern indicating multi-target spread. Rocket in center-right. Icon is clean and readable at 32px. Pixel art icon style.

---

### C2 · `weapon_octo_gun.png` · 64×64
**Prompt:**
2D sci-fi game HUD weapon icon. Dark panel. Six small barrel openings arranged in a circle around a central hub, like a multi-barrel Gatling. Metallic silver-grey with blue highlight dots at each barrel tip. Compact mechanical design. Pixel art icon style.

---

### C3 · `weapon_sonic_jumper.png` · 64×64
**Prompt:**
2D sci-fi game HUD weapon icon. Dark panel. Side-view armored sci-fi boot/gauntlet in cyan-blue. Three horizontal cyan speed lines extending left from the heel. Small circular cyan shockwave ring below the boot. Clean action feel. Pixel art icon style.

---

### C4 · `weapon_blitz_bomb.png` · 64×64
**Prompt:**
2D sci-fi game HUD weapon icon. Dark panel. Round icy bomb with blue-white frosted surface, visible ice crystal texture. Short fuse at top with small yellow spark. Subtle outer cyan glow ring. Cold blue palette (#3CB4F0, #DFFFFF). Pixel art icon style.

---

### C5 · `weapon_spin_laser.png` · 64×64
**Prompt:**
2D sci-fi game HUD weapon icon. Dark panel. Circular green glowing emitter ring. Four green laser beam lines extending outward at 90-degree intervals (up, down, left, right) beyond the ring. Bright green inner circle core. Rotation feel implied by four small arc swoosh marks between beams. Pixel art icon style.

---

### C6 · `weapon_orbital_mayhem.png` · 64×64
**Prompt:**
2D sci-fi game HUD weapon icon. Dark panel. Three small red rockets descending at different angles like a rocket barrage. Small orange explosion burst at bottom center where rockets converge. Sky-to-ground impact feel. Pixel art icon style.

---

### C7 · `weapon_magnetic_field.png` · 64×64
**Prompt:**
2D sci-fi game HUD weapon icon. Dark panel. Horseshoe magnet shape in teal-blue. Red and blue gradient tips (N/S poles). Six small white particle dots orbiting around the magnet in a circular arc. Magnetic field lines implied. Pixel art icon style.

---

## GRUP D — World Object Sprites

### D1 · `sprite_world_bomb.png` · 48×48
**Prompt:**
2D top-down sci-fi game world object sprite. Round metallic bomb. Dark maroon-red metal surface with subtle scratched texture. Bright red glowing circular core at center. Four small metallic bolt heads at N/S/E/W positions on the sphere's equator. Short coiled fuse wire at top with small yellow-orange spark. Soft red danger aura glow around the whole bomb. Transparent background. Pixel art style, top-down view perspective.

---

## Usage Notes

1. **Map Object API**: Use `mcp_pixellab_create_map_object` for all B and D entries  
2. **Icon generation**: Use the icon endpoint or crop from map object results for C entries  
3. **Projectile sprites**: A entries can use map objects; keep size small  
4. After generation: copy object IDs to `scripts/tools/_download_new_assets.py` and run it  
5. Replace PIL placeholder PNGs once PixelLab assets are ready — `.import` files do not need to change  
