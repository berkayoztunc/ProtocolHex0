# GENI HERO — Karakter + UI Tasarım Çizgisi (AI Üretim Rehberi)

Bu doküman, mevcut oyunun sahne/script yapısı taranarak hazırlanmıştır. Amaç: AI ile üretilecek görsellerde **tek bir sanat dili** yakalamak ve **gerçekten gereken asset listesini** netleştirmek.

---

## 1) Sistem Taraması Özeti (Ne gördük?)

Mevcut projede görsellerin büyük kısmı placeholder `ColorRect` ve varsayılan `Control` bileşenlerinden oluşuyor.

- Oynanış varlıkları: `player`, `enemy`, `bullet` tipleri, `xp_gem`, `chest`
- UI katmanları: `start_menu`, `hud`, `level up panel`, `confirm menu`, `perk tree`
- Perk/weapon sisteminde çok sayıda isim ve rarity var, ama **ikon görseli henüz yok**
- Silahlar config üzerinden renk ve davranışla tanımlanmış (Plasma, Tesla, Railgun, Void vb.)

Sonuç: Proje, görsel üretim için hazır bir iskelete sahip; eksik olan şey **karakter sprite seti + UI atlas/icon seti**.

---

## 2) Genel Sanat Yönü (Art Direction)

### Oyun tonu
- Tür: arena/survivor, hızlı tempo, “sci-fi arcade”
- Duygu: güçlenme, net okunabilirlik, yoğun çatışmada dahi sade bilgi akışı
- Öncelik: estetikten önce gameplay okunabilirliği

### Stil kararları
- Perspektif: top-down 2D
- Teknik stil: stylized sci-fi, hafif neon vurgulu, düşük/orta detay
- Kontur: temiz, orta kalınlık, koyu çizgi veya değer kontrastı ile ayrışan siluet
- Materyal dili: enerji/plazma/metal, ama aşırı gerçekçi değil

### Renk dili (önerilen temel)
- Arka plan: koyu lacivert-gri (oyun alanı kontrastı için)
- Dost/oyuncu: cyan-mavi ekseni
- Düşman: kırmızı-magenta ekseni
- Nötr UI yüzeyleri: koyu mavi-gri paneller
- Vurgu rengi: altın/sarı (seçim, kritik, önemli CTA)

### Rarity renkleri (mevcut sistemle uyumlu)
- Common: gri
- Uncommon: yeşil
- Rare: mavi
- Epic: mor
- Legendary: altın

---

## 3) Karakter Tasarım Çizgisi

## 3.1 Oyuncu karakter (Hero)

### Siluet
- Merkezde kompakt, kolay seçilen bir gövde
- Omuz/çekirdek/enerji kaynağı gibi 1-2 ayırt edici form
- 360° okunur; dönüşte kimlik kaybolmamalı

### Tema
- “Teknolojik savaşçı” + enerji çekirdeği
- Ana renk: cyan/mavi, yardımcı: nötr metalik gri
- Vurgu: beyaz-parlak enerji çizgileri

### Durumlar (minimum)
1. Idle / Move temel görünüm
2. Hasar alma flash varyantı (veya ayrı hit sprite)
3. Ölüm anı için parçalanma/solma frame seti (opsiyonel)

### AI prompt çekirdeği (hero)
"Top-down 2D sci-fi hero, compact readable silhouette, cyan energy core, medium stylized detail, clean shape language, game-ready sprite, transparent background, no text"

---

## 3.2 Düşman ailesi

### Zorunlu düşman tipleri
1. **Basic Enemy**
   - Kırmızı ton
   - Basit ama tehditkar siluet
2. **Elite Enemy**
   - Magenta/pembe-mor vurgu
   - Basic’e göre daha büyük veya zırhlı hissi
   - Oyunda elite state zaten var; görselde net ayırt edilmeli

### Düşman tasarım kuralları
- Oyuncudan farklı siluet dili
- Küçük ölçekte de okunmalı
- Animasyon yoksa bile “ileri itilen/agresif” duruş

### AI prompt çekirdeği (enemy)
"Top-down 2D alien/mech enemy sprite, aggressive silhouette, red primary color, clean readability for fast gameplay, stylized sci-fi, transparent background"

Elite için ek: "elite variant, larger mass, magenta glow accents, higher threat visual hierarchy"

---

## 3.3 Pickup ve dünya objeleri

### XP Gem (3 tier)
- Small: yeşil
- Medium: mavi
- Large: altın
- Form: kristal/enerji shard
- Hepsi aynı aileden, sadece ölçek/ışık/rengin gücü değişsin

### Chest
- Sci-fi loot chest
- Kapalı durum yeterli (açılma animasyonu opsiyonel)
- Altın-sarı vurgu + koyu gövde

---

## 4) Silah/VFX Görsel Dili (Karakterle Uyumlu)

Bu projede mermiler tek scene’den davranışla çeşitleniyor. O yüzden AI üretimde yaklaşım:

- Her silah için en az 1 **projectile görünümü**
- Bazı silahlarda ek **impact/explosion/field** sprite’ı

### Weapon görsel aileleri
1. Plasma Rifle — cyan/plazma bolt
2. Nano Swarm — küçük hızlı yeşil-cyan parçacık
3. Tesla Emitter — elektrik arkı, açık mavi
4. Scatter Cannon — turuncu pellet
5. Orbital Sentinel — altın enerji orb
6. Railgun — kırmızı ince penetrasyon beam/slug
7. Void Launcher — mor void orb + patlama halkası
8. Arc Blaster — elektrik yayları (radial)
9. Gravity Pulse — mavi alan dalgası halkası
10. Phase Disruptor — mor dalga (opsiyonel, config’de var)

---

## 5) UI Tasarım Çizgisi

## 5.1 Tasarım prensipleri
- Hızlı okunur HUD
- Kontrastlı ama göz yormayan panel yüzeyleri
- Aksiyon sırasında sadece kritik bilgi öne çıksın
- Aynı component dili: panel, buton, bar, badge, icon

## 5.2 Tipografi önerisi
- Başlık: techno/geometrik sans
- Body: sade sans
- Küçük ebatta okunabilirlik şart

## 5.3 UI component dili
- Panel: koyu zemin + ince açık kenar + hafif iç parlama
- Buton: 3 state (normal / hover / pressed)
- Progress bar: health (kırmızı), xp (mavi-cyan)
- Modal backdrop: yarı saydam koyu
- Rarity badge: common→legendary renk kodu

## 5.4 Ekran bazlı UI yaklaşımı

### Start Menu
- Arka plan illüstrasyonu (soyut neon şehir/arena)
- Logo lockup: “GENI HERO”
- Giriş paneli + buton grubu

### In-game HUD
- Sol üst stat blokları (level/health/xp/kills)
- Sağ üst utility butonları (Perkler / Menü)
- Alt orta aktif silah etiketleri/ikonları
- Sağ alt kontrol yardım paneli

### Level Up Modal
- 3 kart buton (seçenek A/B/C)
- Her kartta rarity + isim + kısa açıklama
- Hover state net ayrışmalı

### Confirm Menu
- Minimal modal + 2 CTA (Evet/Hayır)
- Kontroller toggle alanı

### Perk Tree
- Full-screen koyu overlay
- Node kartları + rarity rengi + bağlantı çizgileri
- Kilitli/aktif/maxed durumları görsel olarak ayrılmalı

---

## 6) Gerekli Görsel Envanteri (Üretim Listesi)

Aşağıdaki liste “oyunun mevcut sistemine göre gerçekten gereken” minimum settir.

## 6.1 Karakter & Dünya (Zorunlu)
1. Hero base sprite (top-down)
2. Hero hit flash overlay (veya alternatif hit sprite)
3. Enemy basic sprite
4. Enemy elite sprite
5. XP gem small (green)
6. XP gem medium (blue)
7. XP gem large (gold)
8. Chest sprite
9. Damage number style sheet (normal + crit görsel stili için)

## 6.2 Silah & VFX (Zorunlu)
1. Plasma projectile
2. Nano projectile
3. Tesla projectile/arc
4. Scatter pellet
5. Orbital orb
6. Railgun shot/beam
7. Void projectile
8. Void explosion ring
9. Arc projectile set (radial)
10. Gravity pulse ring/field

## 6.3 UI Core Pack (Zorunlu)
1. Ana panel arka planı (9-slice uygun)
2. Secondary panel arka planı
3. Button set (normal/hover/pressed/disabled)
4. Input field frame
5. Slider track + thumb
6. Health bar fill + frame
7. XP bar fill + frame
8. Modal backdrop texture (opsiyonel gradient/noise)
9. Perk node frame (locked/unlocked/maxed)
10. Tooltip/description mini panel

## 6.4 UI Icon Pack (Zorunlu)
1. Bomb icon
2. Heal icon
3. Dash icon
4. Targeting mode icon
5. Perk tree icon
6. Menu/settings icon
7. Kill/skull icon
8. Chest/loot icon
9. XP icon
10. Shield/armor icon

## 6.5 Weapon/Upgrade Icon Pack (Zorunlu)
- Plasma Rifle
- Nano Swarm
- Tesla Emitter
- Scatter Cannon
- Orbital Sentinel
- Railgun
- Void Launcher
- Arc Blaster
- Gravity Pulse
- (Opsiyonel) Phase Disruptor

Ayrıca upgrade/perk kategorileri için ikon ailesi:
- Combat, Targeting, Passive Weapon, Active Weapon, Defense, Mobility, Utility

## 6.6 Opsiyonel ama yüksek değerli
- Start menu arka plan illüstrasyonu
- In-game parallax arka plan katmanları
- Hit spark / death burst VFX
- UI micro FX (seviye atlama parlama)

---

## 7) Teknik Üretim Spesifikasyonu (AI çıktı formatı)

### Dosya formatı
- PNG (şeffaf arka plan), gerekirse WEBP
- UI için lossless tercih

### Boyut önerileri
- Karakter/düşman base: 64x64 veya 96x96
- Pickup: 32x32 / 48x48
- Projectile: 16x16, 32x32, beam için 256x32
- UI ikon: 24x24, 32x32, 48x48
- Panel/button: 9-slice için kenar payı bırakılmış atlas

### Pipeline önerisi
1. Önce grayscale form üret
2. Onay sonrası palette boya
3. Sonra glow/vfx katmanı ekle
4. En sonda outline/kontrast kontrolü

---

## 8) AI Prompt Şablonları (Kopyala-kullan)

## 8.1 Global style prompt
"2D top-down sci-fi action game asset, stylized but readable, clean silhouette, medium detail, high gameplay readability, soft neon accents, dark background contrast, production-ready game sprite, transparent background"

## 8.2 UI panel prompt
"Futuristic game UI panel, dark blue-gray material, subtle neon edge highlights, clean hierarchy, readable for action HUD, no text, 9-slice friendly"

## 8.3 Icon prompt
"Game UI icon, sci-fi minimal, high contrast, legible at 24px, consistent stroke weight, transparent background, no text"

## 8.4 Negative prompt (öneri)
"photorealistic, noisy background, tiny unreadable details, text watermark, logo watermark, low contrast, blurry edges"

---

## 9) Üretim Öncelik Sırası (Sprint Planı)

### Sprint 1 (Oynanabilir görsel dönüşüm)
- Hero, Enemy basic/elite, XP gem 3 tier, Chest
- UI core pack (panel/button/bar)
- Silah projectile set (10 adet)

### Sprint 2 (Okunabilirlik + kimlik)
- Weapon/perk icon pack
- Level up/perk tree görsel iyileştirmeleri
- Start menu arka planı

### Sprint 3 (Polish)
- VFX (impact/explosion/hit)
- Ek skin/varyantlar

---

## 10) Notlar (Projeye özel)

- Mevcut kod yapısı görselleri kolayca değiştirilebilir node’lara bağlı; bu yüzden asset entegrasyonu düşük riskli.
- Perk ağacı metin tabanlı çalışıyor; ikon eklemek için her node’a ikon slotu açmak sonraki adım olabilir.
- Renk ayrımı zaten sistemde var, yeni görsellerde bu renk semantiği korunmalı.

---

Hazır olduğunda bir sonraki adım olarak bu envanteri doğrudan dosya yapısına göre (`assets/ui`, `assets/characters`, `assets/vfx`, `assets/icons`) klasörleyip import checklist’i de çıkarabilirim.
