# LinkSaver 

Sosyal medya linklerinizi kolayca kaydedin, klasörlere ayırın ve istediğiniz zaman erişin. Figma tasarımına birebir sadık, Flutter ile geliştirilmiş iOS uygulaması.

---

## Özellikler

- **Link Kaydetme** — URL ve başlık girerek link kaydedin; pano yapıştırma desteği
- **Klasörler** — Linklerinizi klasörlere ayırın, birden fazla klasöre ekleyin
- **Favoriler** — Önemli linkleri yıldızlayın, drawer'dan hızla erişin
- **Otomatik Metadata** — Kaydedilen linkin başlık, açıklama ve favicon bilgisi arka planda çekilir
- **Platform İkonları** — Instagram, YouTube, Twitter/X, TikTok, Reddit, GitHub vb. için marka rengi ve ikonu
- **Kaydırarak Sil** — Link kartını sola kaydırarak silin
- **Arama** — Başlık ve URL'ye göre anlık filtreleme
- **Klasör Detayı** — Klasör içindeki linkleri görün, klasörü yeniden adlandırın veya silin

---

## Ekran Görüntüleri

Figma tasarım dosyaları `assets_design/` klasöründe bulunmaktadır.

---

## Mimari

Proje **Clean Architecture** prensiplerine göre katmanlara ayrılmıştır:

```
lib/
├── core/
│   └── theme/
│       └── app_theme.dart         # Renk paleti (AppColors) + ThemeData
├── models/
│   ├── link_model.dart            # LinkModel (Hive typeId: 0)
│   ├── link_model.g.dart          # Hive TypeAdapter
│   ├── folder_model.dart          # FolderModel (Hive typeId: 1)
│   └── folder_model.g.dart        # Hive TypeAdapter
├── services/
│   ├── storage_service.dart       # Hive CRUD: linkler + klasörler
│   └── metadata_service.dart      # URL metadata çekme (başlık, favicon)
├── screens/
│   ├── home_screen.dart           # Ana ekran — liste, arama, FAB
│   └── folder_detail_screen.dart  # Klasör detay ekranı
├── widgets/
│   ├── link_card.dart             # Kaydırılabilir link kartı
│   ├── save_link_bottom_sheet.dart # Link kaydetme modal'ı
│   ├── folder_drawer.dart         # Sol navigasyon drawer'ı
│   └── logo_widget.dart           # Degrade logo bileşeni
└── main.dart                      # Uygulama giriş noktası, Hive init
```

---

## Renk Paleti

| Değişken | Hex | Kullanım |
|---|---|---|
| `primary` | `#3DC4B0` | Teal — başlıklar, butonlar, FAB |
| `logoStart` | `#E8456A` | Pembe-kırmızı — logo degrade başlangıç |
| `logoEnd` | `#4F72FF` | Mavi-mor — logo degrade bitiş |
| `drawerSectionColor` | `#7B73C4` | Mor — drawer bölüm başlıkları |
| `dateColor` | `#9B8EC4` | Açık mor — kart tarih metni |
| `urlColor` | `#7B8EC8` | Mavi-gri — kart URL metni |
| `searchFill` | `#EEEEF8` | Lavanta — arama çubuğu arka planı |

---

## Kullanılan Paketler

| Paket | Versiyon | Amaç |
|---|---|---|
| `hive_flutter` | ^2.0.0 | Yerel veritabanı |
| `google_fonts` | ^6.2.1 | Poppins yazı tipi |
| `font_awesome_flutter` | ^10.7.0 | Platform marka ikonları |
| `url_launcher` | ^6.3.0 | Tarayıcıda link açma |
| `uuid` | ^4.0.0 | Benzersiz ID üretimi |
| `http` | ^1.2.0 | Metadata HTTP istekleri |

---

## Kurulum

### Gereksinimler

- Flutter SDK 3.16+
- Xcode 15+ (iOS build için)
- CocoaPods

### Adımlar

```bash
# 1. Bağımlılıkları yükleyin
flutter pub get

# 2. iOS pod'larını yükleyin
cd ios && pod install && cd ..

# 3. Uygulamayı çalıştırın
flutter run
```

> **Not:** Hive TypeAdapter'ları (`*.g.dart` dosyaları) repoda hazır mevcuttur.
> `build_runner` çalıştırmanıza gerek yoktur.

---

## Veri Kalıcılığı

Uygulama verisi cihazda **Hive** ile saklanır:

- `links` box — tüm kaydedilen linkler (`LinkModel`)
- `folders` box — kullanıcı klasörleri (`FolderModel`)

Linkler `tags` alanında klasör adlarını saklar. Klasör silindiğinde linkler silinmez; yalnızca o klasör etiketi kaldırılır.

---

## Lisans

MIT License — Dilediğiniz gibi kullanabilirsiniz.