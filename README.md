# Life Manager — Kurulum Talimatları

Bu paket şu ana kadar hazırlanan kısmı içerir: **proje iskeleti, tema sistemi, Ana Sayfa, Görevler ve Finans modülleri, Takvim (temel), Profil (temel)**. Finansın grafik derinliği, bildirimlerin native ayarları ve Takvim/Profil'in geri kalan detayları bir sonraki adımlarda tamamlanacak.

## 1. Projeyi kendi bilgisayarına aç
Bu zip'i istediğin bir klasöre çıkar (örn. `life_manager/`).

## 2. Native platform klasörlerini oluştur
Benim ortamımda Flutter SDK kurulu olmadığı için `android/` ve `ios/` klasörlerini oluşturamadım. Kendi bilgisayarında, proje klasörünün içinde şunu çalıştır:

```bash
cd life_manager
flutter create . --platforms=android,ios --org com.example
```

Bu komut mevcut `lib/` ve `pubspec.yaml` dosyalarına dokunmaz, sadece eksik native klasörleri ekler.

## 3. Paketleri yükle
```bash
flutter pub get
```

## 4. Android bildirim izinleri (önemli)
`android/app/src/main/AndroidManifest.xml` dosyasına, `<application>` etiketinin **dışına**, `<manifest>` içine şunları ekle:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

`minSdkVersion`'ı en az **23** yap (`android/app/build.gradle` içinde `minSdkVersion 23`).

## 5. Çalıştır
```bash
flutter run
```

## Şu ana kadar tamamlanan özellikler
- ✅ Dark/Light tema (Material 3, Poppins font, prompttaki renk paleti)
- ✅ Animasyonlu bottom navigation (5 sekme)
- ✅ Ana Sayfa: dinamik karşılama, tarih, 6 istatistik kartı (fade+scale animasyonlu), bugünkü görevler
- ✅ Görevler: ekleme (başlık, açıklama, tarih, saat, öncelik, kategori, tekrar), tamamlama, silme (kaydırarak), filtreleme
- ✅ Bildirimler: 15 dk önce hatırlatma, tam saatinde alarm, 30 dk sonra tekrar uyarı, 1 saat sonra son hatırlatma (görev tamamlanınca otomatik iptal)
- ✅ Finans: gelir/gider ekleme, bakiye kartı, kategoriye göre pasta grafik, işlem listesi
- ✅ Takvim: aylık grid görünüm, günlere etkinlik ekleme, renkli nokta göstergeleri
- ✅ Profil: tema değiştirme, başarı oranı, ayarlar listesi (yer tutucu)
- ✅ Tüm veriler Hive ile cihazda kalıcı olarak saklanıyor

## Sırada ne var (istersen devam edelim)
- Finans: haftalık/aylık/yıllık çizgi ve çubuk grafikler, istatistikler ekranı
- Takvim: haftalık/günlük görünüm, randevu için harita altyapısı
- Profil: gerçek profil fotoğrafı seçme, PIN/biyometrik giriş entegrasyonu, yedekleme/dışa aktarma
- Lottie başarı animasyonu (görev tamamlanınca)
- Firebase Authentication + Cloud Firestore (opsiyonel senkronizasyon)
