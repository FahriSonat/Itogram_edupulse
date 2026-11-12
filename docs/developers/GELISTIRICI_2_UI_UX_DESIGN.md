# 🎨 Geliştirici 2 Rehberi: UI/UX & Design Lead

Bu belge, **Geliştirici 2 (UI/UX & Design Lead)** rolünün görev alanını, sorumlu olduğu dosyaları, kullandığı görsel teknolojileri ve geliştireceği bileşen standartlarını açıklar.

---

## 📌 1. Rol ve Misyon Özeti

- **Rol / Unvan:** UI/UX & Design Lead
- **Temel Misyon:**
  - Material 3 tasarım dilini projeye mükemmel şekilde uygulamak.
  - Açık (Light) ve Koyu (Dark) tema modlarının (`AppTheme`) tutarlılığını sağlamak, kontrast ve okunabilirlik problemlerini önlemek.
  - Özel grafikler (`CustomPainter` ile Çan Eğrisi vb.), dinamik sayaçlar, QR/PIN panoları ve animasyonlu bileşenleri geliştirmek.
  - Tüm ekranların kullandığı yeniden kullanılabilir (reusable) atomik ve moleküler widget kütüphanesini yönetmek.
  - Sayfa durumlarına özel Shimmer / Skeleton yükleme ekranları, hata ve boş durum kartlarını tasarlamak.

---

## 📂 2. Sorumlu Olduğu Dosya ve Klasörler

Geliştirici 2, tema sabitlerinden ve tüm modüllerin görsel bileşen (`widgets/`) klasörlerinden sorumludur:

```
itogram_edupulse/
└── lib/
    ├── core/
    │   ├── constants/
    │   │   ├── app_colors.dart         # Renk paleti (Birincil, İkincil, Hata, Nötr renkler)
    │   │   ├── app_dimensions.dart     # Padding, Margin, Radius, Elevation sabitleri
    │   │   └── app_strings.dart        # Sabit metinler, uyarılar ve etiketler
    │   ├── theme/
    │   │   ├── app_theme.dart          # ThemeData (Light/Dark), ColorScheme, TextTheme
    │   │   └── theme_cubit.dart        # Tema modu değiştirici (System / Light / Dark)
    │   └── widgets/
    │       ├── main_scaffold_shell.dart # Bottom Navigation Bar & Scaffold kabuğu
    │       ├── app_drawer_menu.dart    # Dinamik sol çekmece menüsü (Role bazlı menü)
    │       ├── custom_app_bar.dart     # Proje genelinde kullanılan standart üst çubuk
    │       ├── role_visibility_guard.dart # Rol yetkisine göre widget göster/gizle bileşeni
    │       ├── countdown_timer_widget.dart# 60 sn veya teslim süresi geri sayım göstergesi
    │       └── state_views/
    │           ├── loading_shimmer_view.dart # İskelet (Skeleton) yükleme animasyonu
    │           ├── error_display_view.dart   # Hata durumu ve 'Tekrar Dene' butonu
    │           └── empty_state_view.dart     # Veri bulunamadı illüstrasyon ve metni
    └── features/
        ├── announcements/presentation/widgets/
        │   ├── announcement_card.dart  # Duyuru kartı (Öncelik rengi & Kategori rozeti)
        │   └── announcement_filter_chips.dart # Filtreleme çipleri
        ├── schedule/presentation/widgets/
        │   ├── interactive_event_calendar.dart # Takvim / Günlük ders gridi
        │   └── schedule_time_slot_card.dart    # Ders başlangıç/bitiş ve amfi kartı
        ├── attendance/presentation/widgets/
        │   ├── dynamic_qr_pin_board.dart       # Öğretmen için 60sn QR ve 6 haneli PIN tahtası
        │   ├── live_attendee_counter_badge.dart# Katılan öğrenci anlık sayaç rozeti
        │   ├── attendance_scanner_overlay.dart # Öğrenci için kamera QR tarama çerçevesi
        │   └── critical_absence_red_list.dart  # %20 risk altındaki öğrencileri gösteren kırmızı kart
        ├── assignments/presentation/widgets/
        │   ├── assignment_countdown_card.dart  # Teslim süresi geri sayım & Geç teslim uyarısı
        │   ├── submission_dropzone_card.dart   # Dosya sürükle-bırak / seç alanı
        │   └── audio_written_feedback_box.dart # Sesli ve yazılı öğretmen geri bildirim kutusu
        ├── grades/presentation/widgets/
        │   ├── bell_curve_chart_painter.dart   # CustomPainter ile çizilen Çan Eğrisi grafiği
        │   ├── gpa_simulator_dashboard.dart    # Not simülatörü slider ve tahmin çubuğu
        │   └── letter_grade_badge.dart         # AA, BA, FF renkli harf notu rozetleri
        └── forum/presentation/widgets/
            ├── question_card.dart              # Soru kartı ve etiketler
            └── voice_playback_card.dart        # Sesli yanıt oynatıcı dalga boyu widget'ı
```

---

## 💻 3. Kullandığı Teknolojiler ve Paketler

| Teknoloji / Paket | Sürüm / Tür | Kullanım Amacı |
|---|---|---|
| **flutter / material** | Material 3 | Modern renk şeması (`ColorScheme.fromSeed`), Card, ListTile, Chip, NavigationBar. |
| **CustomPainter** | Canvas Çizimi | `BellCurveChartPainter` ile Gauss Dağılımı ve çan eğrisinin matematiksel piksel çizimi. |
| **qr_flutter** | QR Generator | Öğretmenin oluşturduğu dinamik ve 60 saniyede bir değişen QR kodunun ekranda render edilmesi. |
| **mobile_scanner** | Kamera / QR Reader | Öğrencinin QR kodu okutması için özel hedefleme kılavuz çizgileri ve animasyonlu tarama çerçevesi. |
| **audioplayers** | Audio Player UI | Öğretmen ve öğrencilerin sesli notları dinleyebileceği oynatıcı çubuğu, duraklatma ve süre göstergesi. |
| **shimmer** | UI Feedback | Sayfa verisi yüklenirken içeriğin yerini alan şık iskelet dalgalanma efekti. |

---

## ⚡ 4. Kritik İş Kuralları ve Görsel Standartlar

### Kural 1: 60 Sn Dinamik Yoklama Ekranı (`DynamicQrPinBoard`)
- Öğretmen ekranında gösterilen QR kod ve 6 haneli PIN kodu 60 saniyede bir otomatik yenilenir.
- Bileşende dairesel bir ilerleme çubuğu (`CircularProgressIndicator` veya lineer bar) 60'tan geriye saymalıdır. Son 10 saniyede renk turuncu/kırmızıya dönmelidir.

### Kural 2: Ödev Teslim Geri Sayım Kartı (`AssignmentCountdownCard`)
- Teslim tarihi geçmemişse: Kalan gün/saat/dakika yeşil/mavi temayla gösterilir.
- Teslim tarihi geçmişse: Kırmızı arka plan ve belirgin bir uyarı rozeti: **"Gecikmeli Teslim: Kural 2 uyarınca teslimden otomatik 10 puan düşülecektir"**.
- Yükleme modalı veya paneli (`_SubmissionDesk`), `AppTheme` kart rengi (`colorScheme.surface`) ile opak açılmalı, arka planı şeffaf kalıp metinleri okunaksız hale getirmemelidir!

### Kural 3: Devamsızlık İlerleme Çubuğu ve Kritik Kırmızı Liste (`CriticalAbsenceRedList`)
- Öğrencinin devamsızlık yüzdesi hesaplanır:
  - `< %15`: Yeşil/Nötr gösterge.
  - `%15 - %19.9`: Sarı/Turuncu ikaz göstergesi.
  - `>= %20`: Yanıp sönen veya kırmızı dolgulu **Kritik Risk** kartı. Öğretmen ekranında bu öğrenciler "Kritik Risk Listesi"nde en tepede listelenir.

### Kural 5: Rol Görünürlük Kalkanı (`RoleVisibilityGuard`)
- Bir butonun veya widget'ın sadece öğretmenler veya sadece öğrenciler tarafından görülmesi gerekiyorsa:
  ```dart
  RoleVisibilityGuard(
    allowedRoles: [UserRole.teacher],
    child: FloatingActionButton(onPressed: _openNewAssignment, child: Icon(Icons.add)),
  )
  ```
  şeklinde sarılarak yetkisiz kullanıcıların arayüzde görmesi engellenir.

---

## 📋 5. Kontrol Listesi (Checklist)

- [ ] Hem Açık (Light) hem Koyu (Dark) temada tüm metinler, kartlar ve butonlar yüksek kontrastla okunabiliyor mu?
- [ ] `CustomPainter` (`BellCurveChartPainter`) farklı ekran boyutlarında taşma (overflow) yapmadan duyarlı (responsive) çizim yapıyor mu?
- [ ] Yükleme (Shimmer), Hata (Error) ve Boş Durum (Empty) görünümleri tüm kartlarda düzgün çalışıyor mu?
- [ ] Geri sayım widget'ları dispose edildiğinde bellek sızıntısını (memory leak) önlüyor mu?

