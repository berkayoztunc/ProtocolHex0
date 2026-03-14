# Assets Folder Map

Bu klasör, AI ile üretilecek görseller için hazırlanmış hedef yapıdır.

- `characters/` → oyuncu
- `enemies/` → düşmanlar
- `pickups/` → xp, chest
- `weapons/` → projectile görselleri
- `vfx/` → impact/ring/efekt
- `ui/panels/` → panel/button/input/slider
- `ui/bars/` → health/xp bar parçaları
- `ui/icons/` → gameplay + weapon ikonları
- `ui/backgrounds/` → menü/backdrop arka planları

Detaylı promptlar: `docs/AI_ASSET_PROMPTS.md`
Detaylı sanat çizgisi: `ART_DIRECTION_UI_CHARACTER.md`
Kontrol listesi: `docs/ASSET_IMPORT_CHECKLIST.md`

## Generated (PixelLab)

- `characters/genihero_ui/` -> Tam karakter paketi (rotations + animations + metadata)
- `ui/icons/icon_player_hero.png` -> UI için tek kare hero ikon/portre
- `ui/backgrounds/character_previews/idle_south/` -> 6 frame idle animasyon
- `ui/backgrounds/character_previews/walk_south/` -> 6 frame walk animasyon

Not: Trial limit nedeniyle 8 yön animasyon yerine south yönünde idle/walk üretildi.
