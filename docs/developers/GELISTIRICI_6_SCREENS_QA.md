# 📱 Geliştirici 6 Rehberi: Feature Screens & QA Lead

Bu belge, **Geliştirici 6 (Feature Screens & QA Lead)** rolünün görev alanını, sorumlu olduğu ekran sayfalarını, form doğrulayıcılarını ve birim/widget/entegrasyon test paketlerini açıklar.

---

## 📌 1. Rol ve Misyon Özeti

- **Rol / Unvan:** Feature Screens & Quality Assurance (QA) Lead
- **Temel Misyon:**
  - Projedeki tüm ekran sayfalarını (`presentation/pages/`) geliştirmek, Geliştirici 2'nin widget'ları ve Geliştirici 5'in Cubit'leri ile buluşturmak.
  - Kullanıcı giriş formları, doğrulayıcılar (`validators.dart`) ve giriş formatlayıcılarını (`input_formatters.dart`) yazmak.
  - Ekran yaşam döngüsü yönetimini (`initState`, `dispose`, `TextEditingController`, `AnimationController`) eksiksiz yönetmek.
  - Kapsamlı test otomasyonunu yürütmek: Birim testleri (Unit Tests), Cubit testleri (`bloc_test`), Arayüz testleri (Widget Tests) ve Taşma/Ekran düzeni (Layout) testlerini yazmak ve yeşilde tutmak.

---

## 📂 2. Sorumlu Olduğu Dosya ve Klasörler

Geliştirici 6, form yardımcılarından, projedeki tüm sayfalardan (`pages/`) ve `test/` klasörünün tamamından sorumludur:

```
itogram_edupulse/
├── lib/
│   ├── core/utils/
│   │   ├── input_formatters.dart    # PIN kodu, telefon, harf/rakam maskeleri
│   │   └── validators.dart          # Email, şifre, PIN (6 hane), not aralığı doğrulama
│   └── features/
│       ├── auth/presentation/pages/
│       │   ├── splash_page.dart     # Açılış ve oturum kontrol yönlendirme ekranı
│       │   └── login_page.dart      # Rol seçimi ve kullanıcı giriş ekranı
│       ├── home/presentation/pages/
│       │   └── home_page.dart       # Öğrenci/Öğretmen ana kontrol paneli (Dashboard)
│       ├── announcements/presentation/pages/
│       │   ├── announcement_list_page.dart   # Duyuru listeleme ve filtreleme ekranı
│       │   └── announcement_detail_page.dart # Duyuru detay ve ek görüntüleme ekranı
│       ├── schedule/presentation/pages/
│       │   └── schedule_page.dart            # Haftalık interaktif ders programı ekranı
│       ├── attendance/presentation/pages/
│       │   ├── attendance_hub_page.dart      # Yoklama ana merkezi (Öğrenci & Öğretmen)
│       │   ├── qr_scanner_page.dart          # Öğrenci QR okuma ve 6 haneli PIN giriş ekranı
│       │   └── absence_report_page.dart      # %20 devamsızlık uyarı ve raporlama ekranı
│       ├── assignments/presentation/pages/
│       │   ├── assignment_list_page.dart     # Aktif, süresi geçen ve puanlanan ödevler
│       │   └── assignment_control_page.dart  # Ödev yükleme desk'i ve öğretmen puanlama ekranı
│       ├── grades/presentation/pages/
│       │   └── grades_page.dart              # Not kartları, çan eğrisi grafiği ve simülatör
│       └── forum/presentation/pages/
│           ├── forum_list_page.dart          # Akademik soru-cevap soru akışı ekranı
│           └── forum_detail_page.dart        # Soru detay, sesli ve yazılı yanıt verme ekranı
└── test/
    ├── core/
    │   ├── utils/validators_test.dart
    │   ├── utils/grade_calculator_test.dart
    │   └── widgets/core_widgets_test.dart
    └── features/
        ├── auth/ (cubit, usecase, widget testleri)
        ├── announcements/ (cubit, widget testleri)
        ├── schedule/ (cubit, widget testleri)
        ├── attendance/ (cubit, dynamic qr testleri)
        ├── assignments/ (cubit, late submission penalty testleri)
        ├── grades/ (cubit, gpa simulator testleri)
        └── forum/ (cubit, voice reply testleri)
```

---

## 💻 3. Kullandığı Teknolojiler ve Paketler

| Teknoloji / Paket | Sürüm / Tür | Kullanım Amacı |
|---|---|---|
| **flutter_test** | Test Çatısı | Widget ağacını render etme (`pumpWidget`), tıklama (`tap`), metin girme (`enterText`), doğrulama (`expect`). |
| **bloc_test** | State Testleri | Cubit'lerin girdi olaylarına karşılık yaydığı durum dizilimini test etme (`whenListen`, `emitsInOrder`). |
| **mocktail** | Mocklama | Use Case, Repository veya Servis sınıflarını izole ederek test ortamında mock'lama. |
| **Form & FormField** | Form Doğrulama | `GlobalKey<FormState>`, `TextFormField`, anlık doğrulama ve kullanıcı geri bildirimleri. |

---

## ⚡ 4. Kritik İş Kuralları ve Ekran Sorumlulukları

### Kural 1: Yoklama Giriş Ekranı (`qr_scanner_page.dart`)
- Öğrenci QR kodunu kamerayla okuttuktan sonra veya kamera çalışmadığında **6 Haneli PIN Kodu** giriş formu sunulur.
- `validators.dart` içindeki `validatePinCode` kullanılır:
  - Tam olarak 6 karakter olmalı.
  - Sadece rakamlardan oluşmalı (`RegExp(r'^[0-9]{6}$')`).
  - Boş bırakılamaz.

### Kural 2: Ödev Teslim Masası (`assignment_control_page.dart`)
- Öğrencinin dosya yüklediği `_SubmissionDesk` modal ekranı:
  - Arka plan rengi tema kart rengine (`Theme.of(context).colorScheme.surface`) bağlanmıştır; şeffaf açılamaz, metinler net okunur.
  - Eğer teslim tarihi geçmişse sayfada kırmızı ikaz: *"Gecikmeli Teslim: Teslim edebilirsiniz ancak Kural 2 gereğince 10 puan ceza kesilecektir."*
  - Yükleme butonuna tıklandığında yükleme progress barı gösterilir.

### Kural 3: Devamsızlık Rapor Ekranı (`absence_report_page.dart`)
- Sayfa açıldığında öğrencinin ders bazlı devamsızlıkları listelenir.
- Devamsızlığı `%20` üzerinde olan derslerin kartları en üstte kırmızı uyarı çerçevesi ve "KALMA RİSKİ / KRİTİK EŞİK" başlığı ile yer alır.

### Kural 5: Sayfa Düzeyinde Rol Kontrolleri
- Her sayfa, kullanıcının rolüne göre dinamik davranır:
  - Öğretmen ise: "Yeni Ödev Ekle", "Yoklama Başlat", "Not Gir" butonları aktif.
  - Öğrenci ise: "Ödev Yükle", "Yoklamaya Katıl (QR/PIN)", "Not Simülatörü" modları aktif.

---

## 🧪 5. Test Yazım ve Çalıştırma Rehberi

Tüm testleri tek seferde çalıştırmak için terminal komutu:
```powershell
flutter test
```

Özel modül testleri çalıştırma örneği:
```powershell
flutter test test/features/assignments/
flutter test test/core/utils/grade_calculator_test.dart
```

### Örnek Cubit Test Şablonu (`bloc_test`):
```dart
blocTest<AssignmentCubit, AssignmentState>(
  'Kural 2: Geç teslim edilen ödevde isLate true ve 10 puan ceza yayılmalıdır',
  build: () => AssignmentCubit(mockSubmitAssignmentUseCase),
  act: (cubit) => cubit.submitAssignment(assignmentId: '1', file: mockFile, isLate: true),
  expect: () => [
    isA<AssignmentSubmitting>(),
    isA<AssignmentSubmitSuccess>().having((s) => s.isLate, 'isLate', true),
  ],
);
```

---

## 📋 6. Kontrol Listesi (Checklist)

- [ ] Tüm `TextEditingController` ve `ScrollController` nesneleri `dispose()` içinde temizleniyor mu?
- [ ] Klavyenin ekranı kapatması durumunda (`SingleChildScrollView` veya `resizeToAvoidBottomInset`) taşma (A RenderFlex overflowed) hatası alınıyor mu?
- [ ] `flutter test` çalıştırıldığında projedeki tüm testler (472+ test) yeşil geçiyor mu?
- [ ] Tüm formlarda geçersiz girdilerde (`validator`) kullanıcıya anlaşılır Türkçe hata mesajları veriliyor mu?

