# GeniHero - Mevcut Oyun Durumu

Bu belge, projenin kod tabanına göre oyunun şu anki oynanabilir durumunu, içeriklerini ve ilerleme sistemlerini özetler.

## Genel Durum

GeniHero şu anda arena survival ve auto-shooter yapısında çalışan bir prototip durumunda.

- Oyuncu hareket edebiliyor.
- Düşmanlar sürekli spawn oluyor.
- Oyuncu otomatik pasif silahlarla saldırıyor.
- Aktif silahlar belirli tuşlarla kullanılabiliyor.
- XP gemleri toplanıyor ve seviye atlanıyor.
- Seviye atlayınca 3 seçenekli upgrade ekranı geliyor.
- Düşmanlardan sandık düşebiliyor ve ekstra perk seçimi veriyor.
- Son koşu kaydediliyor ve devam ettirme desteği bulunuyor.
- HUD üzerinde can, XP, level, kill, aktif silah, targeting ve aktif mermi tipi bilgisi gösteriliyor.

## Oyun Döngüsü

Temel döngü şu şekilde çalışıyor:

1. Oyuncu arena içinde hareket eder.
2. Düşmanlar oyuncuya doğru akar.
3. Oyuncu pasif silahlarla otomatik saldırır.
4. Düşmanlar öldüğünde XP gemi ve bazen sandık bırakır.
5. Oyuncu XP toplayarak level alır.
6. Her level up veya sandık açılışında 3 yükseltme arasından seçim yapılır.
7. Zaman ve kill arttıkça düşmanlar güçlenir.
8. Oyuncu ölünce koşu biter ve kayıt son run olarak saklanır.

## Başlangıç ve Kayıt Sistemi

- Başlangıç menüsünde oyuncu adı girilebilir.
- Son koşu varsa Continue seçeneği açılır.
- Oyuncunun son run durumu profile kaydedilir.
- Kaydedilen veriler arasında level, XP, can, açılmış silahlar, targeting modu, açılmış mermi tipleri ve upgrade stack bilgileri vardır.

Bu sistem meta progression değil, daha çok son koşuyu sürdürme mantığına yakın çalışır.

## Karakter Özellikleri

Oyuncunun temel veya geliştirilebilir istatistikleri şunlardır:

- Can
- Maksimum can
- Hareket hızı
- Atış bekleme süresi
- Silah hasarı
- Mermi sayısı
- Kritik şansı
- Kritik çarpanı
- Delme sayısı
- Yanma şansı
- Yanma hasarı
- Zırh
- Can yenileme
- Dash şarjı
- XP çarpanı
- Enerji kalkanı

## Kontroller

- WASD veya yön tuşları: hareket
- Q: bomba kullan
- E: heal charge kullan
- Shift: dash
- Tab: targeting modu değiştir
- C: açılmış mermi tipleri arasında geçiş
- 1, 2, 3, 4, 5: aktif silahlar
- P: perk ağacını aç / kapat

Not: C ile geçiş yalnızca alternatif mermi tipleri unlock edildikten sonra çalışır.

## Mevcut Silahlar

### Başlangıç Silahı

- Plasma Rifle

Bu silah oyuncunun başlangıç pasif silahıdır.

### Pasif Silahlar

- Plasma Rifle
- Nano Swarm
- Tesla Emitter
- Scatter Cannon
- Orbital Sentinel

### Aktif Silahlar

- Railgun [1]
- Void Launcher [2]
- Arc Blaster [3]
- Gravity Pulse [5]

### Kodda Tanımlı Ama Oyunda Bağlı Görünmeyen Silah

- Phase Disruptor [4]

Bu silah konfigürasyonda tanımlı durumda ancak mevcut unlock havuzu ve upgrade akışında erişilebilir görünmüyor.

## Silah Özellikleri

### Plasma Rifle

- Temel başlangıç silahı
- Tek hedefe odaklı atış
- Pasif silah

### Nano Swarm

- Çok hızlı atış yapar
- Düşük hasarlı ama çok sayıda mermi üretir
- Pasif silah

### Tesla Emitter

- Elektrik temalıdır
- Hedefler arasında zincirleme sıçrayabilir
- Pasif silah

### Scatter Cannon

- Geniş açıyla çoklu pellet atar
- Yakın veya orta mesafede güçlüdür
- Pasif silah

### Orbital Sentinel

- Oyuncunun çevresinde dönen enerji küreleri oluşturur
- Yaklaşan düşmanlara sürekli temas hasarı sağlar
- Pasif silah

### Railgun

- Güçlü tek atış
- Çok yüksek delme kapasitesi vardır
- 1 tuşuyla kullanılır
- Aktif silah

### Void Launcher

- Yavaş ama güçlü bir patlayıcı mermi atar
- Alan hasarı verir
- 2 tuşuyla kullanılır
- Aktif silah

### Arc Blaster

- Çok yönlü elektrik atışı yapar
- Radyal dağılım üretir
- 3 tuşuyla kullanılır
- Aktif silah

### Gravity Pulse

- Yakındaki düşmanlara hasar verir
- Düşmanları oyuncudan uzağa iter
- 5 tuşuyla kullanılır
- Aktif silah

### Phase Disruptor

- Tanım olarak ekrandaki tüm düşmanlara dalga hasarı verir
- Şu an erişilebilir akışa bağlı görünmüyor

## Targeting Modları

Oyuncunun nişan davranışı upgrade ile genişliyor ve Tab ile değiştiriliyor.

- Forward
- Rear Guard
- Side Sweep
- Full Spread
- Orbital Fire

### Forward

- En yakın veya uygun hedefe normal atış

### Rear Guard

- İleri ve geri yönde ateş eder

### Side Sweep

- Sol ve sağ yöne ateş eder

### Full Spread

- İleri ve çapraz açılarda fan şeklinde ateş eder

### Orbital Fire

- Spiral veya dairesel pattern ile atış üretir

## Mermi Tipleri

Oyuncu başlangıçta yalnızca standart mermi ile başlar. Diğer mermi sınıfları perk olarak alınmalıdır.

- Standart
- Patlayıcı
- Sekebilen
- Işın

### Standart

- Başlangıçta açık olan temel mermi tipidir

### Patlayıcı

- Vuruş noktasında alan hasarı oluşturur
- Unlock gerektirir

### Sekebilen

- Bir hedeften diğerine sekebilir
- Unlock gerektirir

### Işın

- Kısa süreli beam şeklinde hasar verir
- Unlock gerektirir

## Perk Kategorileri

Mevcut perk sistemi şu kategorilere ayrılmış durumda:

- Combat
- Targeting
- Pasif Silahlar
- Aktif Silahlar
- Savunma
- Hareketlilik
- Yardımcı

## Mevcut Perkler

### Combat

- Saldırı Hızı
- Silah Hasarı
- Ek Mermi
- Kritik Şansı
- Delici Mermi
- Yakıcı Atış

### Targeting

- Arka Nişan
- Yan Tarama
- Tam Yelpaze
- Orbital Ateş

### Mermi Tipi Perkleri

- Patlayıcı Mermi açma
- Sekebilen Mermi açma
- Işın Mermi açma

### Pasif Silah Perkleri

- Nano Swarm açma
- Nano Swarm güçlendirme
- Tesla Emitter açma
- Tesla Emitter güçlendirme
- Scatter Cannon açma
- Scatter Cannon güçlendirme
- Orbital Sentinel açma
- Orbital Sentinel güçlendirme

### Aktif Silah Perkleri

- Railgun açma
- Railgun güçlendirme
- Void Launcher açma
- Void Launcher güçlendirme
- Arc Blaster açma
- Arc Blaster güçlendirme
- Gravity Pulse açma
- Gravity Pulse güçlendirme

### Savunma

- Maksimum Can
- Can Yenileme
- Zırh
- Enerji Kalkanı

### Hareketlilik

- Hız
- XP Mıknatısı
- Faz Kayması

### Yardımcı

- Anlık İyileşme
- Bomba Şarjı
- Heal Şarjı
- XP Çarpanı

## Güçlendirme Sistemi

Yükseltmeler run içinde birikiyor ve çoğunun stack limiti bulunuyor.

Örnek limitler:

- Saldırı Hızı: 8
- Silah Hasarı: 10
- Ek Mermi: 5
- Hız: 7
- Maksimum Can: 8
- Kritik Şansı: 5
- Delici Mermi: 3
- Yakıcı Atış: 4
- Life Regen: 5
- Zırh: 5
- XP Mıknatısı: 5
- Dash: 3
- XP Çarpanı: 5
- Çoğu unlock perk: 1
- Çoğu silah upgrade perk: 3

Bazı perkler prerequisites kullanır. Örneğin bir silahın upgrade perkini almak için önce o silahın unlock perkini almak gerekir.

## Karakter Güçlendirmesi Nasıl İşliyor

Perkler oyuncuyu şu yollarla güçlendiriyor:

- Atış süresini azaltma
- Can kapasitesini artırma
- Hareket hızını artırma
- Zırh ekleme
- Saniyelik can yenilenmesi ekleme
- XP toplama hızını ve verimini artırma
- Dash kullanabilme
- Kalkan açma
- Yeni pasif silah açma
- Yeni aktif silah açma
- Var olan silahların ayrı upgrade seviyelerini yükseltme

Silah upgrade sistemi genel stat yerine çoğunlukla silah bazlı upgrade level mantığıyla çalışıyor.

## Düşman ve Zorluk Sistemi

Mevcut durumda tek bir temel düşman tipi var.

- Oyuncuya doğru yürür
- Temas edince hasar verir
- Can barı vardır
- Elite varyantı üretilebilir

Zorluk artışı şu başlıklarda çalışıyor:

- Spawn aralığı zamanla düşer
- Düşman canı artar
- Düşman hızı artar
- Düşman hasarı artar
- Elite çıkma ihtimali zamanla yükselir
- Fiziksel ve patlayıcı direnç artabilir

## XP ve Sandık Sistemi

### XP Sistemi

- Düşman ölünce XP gem düşer
- Gem tierleri small, medium ve large olarak ayarlanmış
- Büyük gemler kill sayısı ilerledikçe daha erişilebilir olur
- XP ihtiyacı level arttıkça artar

### Sandık Sistemi

- Belirli kill aralıklarında veya şansa bağlı sandık düşebilir
- Aynı anda sahada sınırlı sayıda sandık tutulur
- Sandık açıldığında 3 ödül seçeneği sunulur

## Perk Ağacı Ekranı

Oyunda perk ağacı ekranı vardır ancak bu ekran kalıcı meta tree değil, mevcut run içinde alınmış perklerin görsel izleme ekranı gibi çalışır.

- P ile açılır
- ESC veya tekrar açma ile kapanır
- Kategorilere ayrılmıştır
- Prerequisite bağlantılarını görsel olarak gösterir
- Hangi perklerin açıldığı, kilitli olduğu veya maksimum stacke ulaştığı izlenebilir

## Teknik Olarak Dikkat Çeken Eksik veya Yarım Alanlar

Mevcut kod yapısına göre bazı sistemler tanımlı olsa da tam bağlanmamış görünüyor:

### 1. Genel silah statları tam etkili olmayabilir

- Silah Hasarı
- Ek Mermi
- kısmen Saldırı Hızı

Bu perkler oyuncu üzerinde stat artırıyor ancak gerçek ateş sistemi çoğu durumda weapon definition ve weapon-specific upgrade level üzerinden hesap yapıyor. Bu nedenle bu perkler beklenen kadar etkili çalışmıyor olabilir.

### 2. Yakıcı Atış tamamlanmamış görünüyor

- Burn chance ve burn damage stat olarak artıyor
- Ancak mermi veya düşman tarafında yanma etkisini sürdüren açık bir uygulama görünmüyor

### 3. Enerji Kalkanı açıklama ile birebir örtüşmüyor

- Açıklama ölümcül darbeyi engeller diyor
- Kod tarafında aktifken ilk gelen hasarı tamamen emiyor

### 4. Dash yenilenmiyor

- Dash şarjı perk ile kazanılıyor
- Kullanılınca azalıyor
- Zamanla dolan bir sistem görünmüyor

### 5. Phase Disruptor erişilebilir değil

- Tanımı var
- Aktif silah davranışı da var
- Ancak unlock veya seçim havuzunda görünmüyor

## Kısa Sonuç

GeniHero şu anda oynanabilir çekirdeği olan, içerik çeşitliliği oluşmuş, upgrade ve build mantığı oturmaya başlamış bir prototip.

Güçlü tarafları:

- Net oyun döngüsü
- Silah çeşitliliği
- Run içi build oluşturma
- Perk ağacı görünümü
- Save and continue desteği

Geliştirilmesi gereken tarafları:

- Bazı perklerin gerçek etkisinin tamamlanması
- Tanımlı ama erişilemeyen içeriklerin bağlanması
- Stat sisteminin daha tutarlı hale getirilmesi
- Düşman çeşitliliğinin artırılması
