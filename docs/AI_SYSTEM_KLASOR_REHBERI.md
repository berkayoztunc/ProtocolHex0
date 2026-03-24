# GeniHero — AI Sistem ve Klasör Rehberi

Bu doküman, projeye katılan AI ajanlarının kod tabanını hızlı anlaması için hazırlanmıştır.
Amaç: **hangi sistem nerede**, **hangi dosya neyi yönetiyor**, **değişiklik yaparken nereden başlanır** sorularına net cevap vermek.

---

## 1) Proje Özeti

- Oyun motoru: **Godot 4.6**
- Tür: **Top-down arena survival / auto-shooter**
- Başlangıç sahnesi: `res://scenes/start_menu.tscn`
- Ana oyun sahnesi: `res://scenes/main.tscn`

Yüksek seviyeli akış:
1. Start menü (`start_menu.tscn`) → New Run / Continue
2. Main sahnesi (`main.tscn`) yüklenir
3. `game_manager.gd` dalga/spawn/ödül/perk akışını yönetir
4. Oyuncu (`player.gd`) hareket + silah + perk etkilerini uygular
5. HUD (`hud.gd`) canlı verileri ve level-up/perk UI’ı gösterir

---

## 2) Kritik Dizinler

## `scenes/`
Oyunun sahne kompozisyonu.

Önemli dosyalar:
- `main.tscn`: Oyun root’u (GameManager + Player + HUD + background/hazard)
- `start_menu.tscn`: Başlangıç menüsü
- `player.tscn`: Oyuncu node yapısı
- `enemy.tscn`: Düşman temel sahnesi
- `hud.tscn`: Oyun içi UI + modal paneller
- `perk_tree.tscn`: Perk ağacı UI kök sahnesi
- `bullet/aoe_bullet/bouncing_bullet/beam_bullet.tscn`: mermi sınıfları
- `xp_gem.tscn`, `chest.tscn`, `world_bomb.tscn`: pickup/ödül objeleri

## `scripts/`
Gameplay mantığı.

Alt klasörler:
- `scripts/autoload/`: global singleton servisler
- `scripts/world/`: oyun dünya akışı (spawn, dalga, ödül, çevre)
- `scripts/entities/`: Player/Enemy davranışları
- `scripts/projectiles/`: mermi davranışları
- `scripts/ui/`: HUD, menü, perk ağacı, skill bar
- `scripts/tools/`: asset/import otomasyon scriptleri (oyun runtime parçası değil)

## `assets/`
Sprite, UI, VFX, karakter, düşman, pickup, tile ve shader kaynakları.

## `docs/`
Mevcut tasarım/asset/not dökümanları.

---

## 3) Autoload (Global Servisler)

`project.godot` içinde yüklü singletonlar:

- `Session` → `scripts/autoload/session.gd`
  - Oyuncu profili, son run state’i, continue/new run akışı
  - Persistence: `user://player_profile.json`

- `MockApiClient` → `scripts/autoload/mock_api_client.gd`
  - Telemetry/event queue mock akışı

- `ConfigService` → `scripts/autoload/config_service.gd`
  - Tüm denge/config değerleri (waves, difficulty, enemies, weapons, vb.)
  - Çoğu sistem için **single source of truth**

- `UpgradeCatalogs` → `scripts/autoload/upgrade_catalogs.gd`
  - Perk katalogu, layout ve kategori verileri

---

## 4) Sistem Sahipliği (Hangi Mantık Nerede)

## A) Oyun döngüsü / dalga / spawn
Ana dosya: `scripts/world/game_manager.gd`

Sorumluluklar:
- Dalga üretimi ve burst schedule
- Düşman spawn + archetype seçimi
- Kill sayacı, XP gem ve chest spawn
- World bomb düşürme
- Level-up seçenekleri/perk ekranı tetikleme
- HUD güncellemeleri için oyuncu sinyallerine bağlanma
- Run state autosave / persist

## B) Oyuncu, silahlar, statlar
Ana dosya: `scripts/entities/player.gd`

Sorumluluklar:
- Hareket, input, dash/heal/bomb kullanımı
- Passive ve held(active slot) silah firing akışı
- Targeting mode cycle (`Tab`)
- Projectile class cycle (`C`) ve unlock kontrolü
- Stat/perk etkilerini uygulama (crit, armor, life regen, vb.)
- XP alma, level atlama, can ve ölüm sinyalleri

## C) Düşman davranışı ve archetype
Ana dosya: `scripts/entities/enemy.gd`

Sorumluluklar:
- Melee/ranged düşman davranışı
- `ConfigService` fire profile uygulaması
- Durum efektleri (burn/chill gibi)
- Hasar alma/ölüm ve ölçekleme parametreleri

## D) UI / HUD / modal akışlar
Ana dosyalar:
- `scripts/ui/hud.gd`
- `scripts/ui/perk_tree.gd`
- `scripts/ui/start_menu.gd`
- `scripts/ui/skill_bar.gd`

Sorumluluklar:
- Health/XP/level/kill/weapon göstergeleri
- Level-up seçim modalı
- Oyun sonu paneli
- Perk ağacı etkileşimi
- Start/Continue/Settings/Controls menüsü

## E) Dünya yardımcı sistemleri
`scripts/world/` altı:
- `enemy_pool.gd`: pool yönetimi
- `background_tiler.gd`: zemin/hazard görsel düzeni
- `hazard_collider.gd`: hazard collision hasarı
- `xp_gem.gd`, `chest.gd`, `world_bomb.gd`: pickup/objeler
- `damage_number.gd`, `vfx_*`: görsel combat feedback

---

## 5) Veri ve Konfigürasyon Kaynakları

### Runtime config
- Ana kaynak: `ConfigService.config`
- Başlıca bölümler:
  - `waves`
  - `difficulty`
  - `xp`
  - `chest`
  - `enemies.archetypes`
  - `enemies.fire_profiles`
  - `weapons.definitions`

### Persist edilen run/profile verisi
- Kaynak: `Session`
- Dosya: `user://player_profile.json`
- İçerik: level/xp/health, perk stack, unlocked yapılar, son run bilgisi

### Perk katalogu
- Kaynak: `UpgradeCatalogs`
- İçerik: perk id, açıklama, rarity, prerequisites, UI layout(row/col)

---

## 6) AI için Hızlı Navigasyon Reçetesi

## “Yeni bir gameplay özellik ekleyeceğim”
1. `scripts/world/game_manager.gd` (tetik ve akış)
2. `scripts/entities/player.gd` (etki uygulama)
3. `scripts/autoload/config_service.gd` (denge/config)
4. Gerekirse `scripts/ui/hud.gd` (görünürlük/feedback)

## “Yeni perk ekleyeceğim”
1. `scripts/autoload/upgrade_catalogs.gd` içine perk tanımı
2. Gerekirse `player.gd` veya `game_manager.gd` içinde perk effect handler
3. UI otomatik perk tree layout ile görünür (row/col verilirse)

## “Yeni düşman türü ekleyeceğim”
1. `ConfigService` → `enemies.archetypes` içine giriş
2. Gerekirse `enemies.fire_profiles` tanımı
3. Asset path’leri (`sprite_path`, `char_base_path`) doğrulama
4. `enemy.gd` behavior anahtarlarıyla uyumluluk kontrolü

## “Yeni aktif silah ekleyeceğim”
1. `ConfigService.weapons.definitions` içine silah tanımı (slot_key dahil)
2. Unlock/upgrade perklerini `UpgradeCatalogs`’a ekle
3. `player.gd` içinde gerekiyorsa özel davranış branch’i aç
4. HUD skill bar gösterimini doğrula

---

## 7) Dikkat Edilecek Noktalar

- Bu projede bazı eski dokümanlar ve mevcut runtime davranışı arasında fark olabilir.
  - Karar verirken öncelik sırası: **script runtime > sahne bağlantısı > eski döküman**
- `scripts/_backup/` ve `scenes/v1_backup`, `scenes/v2_backup` aktif oyun akışının parçası değildir.
- Asset pipeline için `scripts/tools/` Python scriptleri kullanılır; gameplay runtime ile karıştırılmamalıdır.

---

## 8) AI Agent “Do / Don’t”

### Do
- Önce `project.godot` + `main.tscn` + `game_manager.gd` okuyarak sistem bağlamı çıkar.
- Yeni mekanikleri mümkün olduğunca `ConfigService` üzerinden parametreleştir.
- UI etkisi varsa `hud.gd` sinyal bağlantılarını ve görünür metinleri güncelle.
- Değişiklikleri küçük ve izole tut.

### Don’t
- `backup` klasörlerini canlı kaynak sanma.
- Config yerine hard-coded magic number çoğaltma.
- Perk id / weapon id adlandırma düzenini bozma (snake_case id).
- Tek dosyada devasa refactor yapma; sistem sahipliğini koru.

---

## 9) Kısa Dosya Haritası (En Çok Dokunulanlar)

- `project.godot` → autoload + input + katmanlar
- `scenes/main.tscn` → canlı gameplay composition
- `scripts/world/game_manager.gd` → run orchestration
- `scripts/entities/player.gd` → player combat/stat/input
- `scripts/entities/enemy.gd` → enemy AI + projectile fire profile
- `scripts/autoload/config_service.gd` → balancing/config merkezi
- `scripts/autoload/upgrade_catalogs.gd` → perk tanımları + layout
- `scripts/autoload/session.gd` → profile/save/continue
- `scripts/ui/hud.gd` → oyun içi HUD + modal UI
- `scripts/ui/perk_tree.gd` → perk tree ekranı
- `scripts/ui/start_menu.gd` → ana menü akışı

---

Bu rehber, AI ajanlarının ilk 10 dakikada projeye adapte olması için hazırlanmıştır.
Ek ihtiyaçta bu dosyaya “Feature Playbook” bölümü (örn. yeni silah ekleme checklist’i) eklenebilir.