# 🚀 EduPulse — Geliştirici Görev Dağılımı ve Çalışma Kılavuzları

Bu dizin, **EduPulse — Mimari ve Dosya Bazlı Geliştirme Şartnamesi** uyarınca projede görev alan 6 farklı geliştirici rolünün özel çalışma rehberlerini, sorumlu oldukları dosya ağacını, kullandıkları teknoloji ve paketleri, uygulayacakları kritik iş kurallarını (Kural 1-5) ve mimari standartları içermektedir.

---

## 👥 Ekip Rol Dağılımı Özeti

| No | Rol / Unvan | Ana Odak ve Katmanlar | Dosya Rehberi |
|---|---|---|---|
| **1** | **Team Lead & Core Arch Lead** | Mimari Omurga, DI (`get_it`), Router (`go_router`), Core Error/Enums/Utils, Kalite Standartları | [GELİŞTİRİCİ 1 REHBERİ](file:///c:/Users/FAHRIASUS/Desktop/itogram_edupulse/docs/developers/GELISTIRICI_1_CORE_ARCH.md) |
| **2** | **UI/UX & Design Lead** | Tasarım Sistemi (`AppTheme`), Animasyonlar, Özel Grafikler (`CustomPainter`), Ortak ve Feature Widget Bileşenleri | [GELİŞTİRİCİ 2 REHBERİ](file:///c:/Users/FAHRIASUS/Desktop/itogram_edupulse/docs/developers/GELISTIRICI_2_UI_UX_DESIGN.md) |
| **3** | **Network & Firebase Lead** | Firebase Entegrasyonları, Firestore/Storage Güvenlik Kuralları, Donanım Servisleri (FCM, Ses, Dosya) & Data Sources/Repos | [GELİŞTİRİCİ 3 REHBERİ](file:///c:/Users/FAHRIASUS/Desktop/itogram_edupulse/docs/developers/GELISTIRICI_3_NETWORK_FIREBASE.md) |
| **4** | **Data Models & DTO Lead** | Domain Entities, Repository Interface'leri, Data DTO Models (`fromJson`/`toJson`/`fromFirestore`/`toFirestore`), Firestore Koleksiyon Sabitleri | [GELİŞTİRİCİ 4 REHBERİ](file:///c:/Users/FAHRIASUS/Desktop/itogram_edupulse/docs/developers/GELISTIRICI_4_DATA_MODELS.md) |
| **5** | **State & Logic Lead** | Domain Use Cases, BLoC/Cubit State Yönetimi, Stream & Timer Senkronizasyonları (60sn Yoklama, Canlı Akışlar) | [GELİŞTİRİCİ 5 REHBERİ](file:///c:/Users/FAHRIASUS/Desktop/itogram_edupulse/docs/developers/GELISTIRICI_5_STATE_LOGIC.md) |
| **6** | **Feature Screens & QA Lead** | Tüm Ekran Sayfaları (`pages/`), Form & Giriş Doğrulayıcılar (`validators.dart`), Test Otomasyonu (Birim, Cubit, Widget, Layout Testleri) | [GELİŞTİRİCİ 6 REHBERİ](file:///c:/Users/FAHRIASUS/Desktop/itogram_edupulse/docs/developers/GELISTIRICI_6_SCREENS_QA.md) |

---

## 🔒 5 Kritik İş Kuralı (Business Rules) ve İlgili Geliştiriciler

1. **Kural 1 — 60 Sn Dinamik Yoklama Kalkanı:**
   - *Aktörler:* Geliştirici 1 (Enums), Geliştirici 2 (QR/PIN Widget), Geliştirici 3 (Firestore & Security Rules), Geliştirici 4 (Attendance Models), Geliştirici 5 (Cubit Timer & Validation Logic), Geliştirici 6 (Attendance Page & Tests).
2. **Kural 2 — Ödev Zaman Kalkanı ve Ceza Mekanizması (-10 Puan):**
   - *Aktörler:* Geliştirici 4 (Submission Entity/Model), Geliştirici 5 (Submit Assignment Use Case / Cubit), Geliştirici 2 (Geri Sayım Kartı & Ceza Rozeti), Geliştirici 6 (Assignment Control Page & Form).
3. **Kural 3 — %20 Devamsızlık Uyarı Motoru ve Otomatik FCM Bildirimi:**
   - *Aktörler:* Geliştirici 3 (FCM Notification Service & Trigger), Geliştirici 4 (Absence Record Model), Geliştirici 5 (Absence Tracking Cubit), Geliştirici 2 (Kritik Risk Listesi & İlerleme Çubuğu).
4. **Kural 4 — Harf Notu ve Ağırlıklandırma Motoru:**
   - *Formula:* `Not = Vize * 0.40 + Final * 0.60 + Bonus` (Maksimum 100).
   - *Aktörler:* Geliştirici 1 (GradeCalculator Utils), Geliştirici 4 (Grade Model & Letter Grade Enum), Geliştirici 2 (Çan Eğrisi Grafiği & Not Simülatörü), Geliştirici 5 (Grade Cubit).
5. **Kural 5 — Mutlak Rol Güvenliği (RBAC):**
   - *Aktörler:* Geliştirici 1 (RoleGuard Router & UserRole Enum), Geliştirici 2 (RoleVisibilityGuard Widget), Geliştirici 3 (`firestore.rules` & `storage.rules`), Geliştirici 6 (Ekran erişim yetkilendirme testleri).

---

## 📐 Katmanlı Mimari Şeması (Clean Architecture)

```
       [ PRESENTATION LAYER ]
    Pages (Geliştirici 6)  <--->  Widgets (Geliştirici 2)
              │
         Cubit/State (Geliştirici 5)
              │
       [ DOMAIN LAYER ]
    Use Cases (Geliştirici 5)  <--->  Entities (Geliştirici 4)
              │                           │
    Repository Interfaces (Geliştirici 4) ┘
              │
       [ DATA LAYER ]
    Repository Implementations (Geliştirici 3)
              │
    Data Sources (Geliştirici 3)  <--->  Models/DTOs (Geliştirici 4)
              │
       [ CORE & PLATFORM ]
    Firebase / Hardware Services (Geliştirici 3)
    DI, Router, Core Utils, Enums (Geliştirici 1)
```

Her geliştirici kendi çalışma rehberine giderek yapacağı işleri adım adım takip edebilir!

