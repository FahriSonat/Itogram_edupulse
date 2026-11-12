# 🛠️ Geliştirici 1 Rehberi: Team Lead & Core Architecture

Bu belge, **Geliştirici 1 (Team Lead & Core Arch)** rolünün görev alanını, sorumlu olduğu dosyaları, kullandığı teknolojileri ve projeyi yönetirken dikkat etmesi gereken kritik standartları açıklar.

---

## 📌 1. Rol ve Misyon Özeti

- **Rol / Unvan:** Team Lead & Core Architecture Lead
- **Temel Misyon:**
  - Projenin Clean Architecture omurgasını kurmak, korumak ve geliştirmek.
  - Bağımlılık Enjeksiyonu (Dependency Injection - DI) container'ını yönetmek.
  - Sayfa yönlendirmelerini (Routing) ve rol tabanlı erişim kontrolünü (Role Guard) garanti altına almak.
  - Çekirdek Hata Yönetimi (`Failure` ve `Exception` sınıfları) ve Enum hiyerarşisini belirlemek.
  - Kod kalitesi, paket bağımlılıkları ve analiz kurallarını (`analysis_options.yaml`, `pubspec.yaml`) denetlemek.

---

## 📂 2. Sorumlu Olduğu Dosya ve Klasörler

Geliştirici 1 doğrudan aşağıdaki dosyalardan ve çekirdek altyapıdan sorumludur:

```
itogram_edupulse/
├── pubspec.yaml                     # Proje paket bağımlılıkları ve versiyonlama
├── analysis_options.yaml            # Linter ve strict kod analiz kuralları
├── lib/
│   ├── main.dart                    # Uygulama giriş noktası (Firebase & DI init)
│   ├── app.dart                     # MaterialApp.router, AppRouter, Theme injection
│   └── core/
│       ├── config/
│       │   ├── firebase_options.dart # Firebase CLI platform konfigürasyonları
│       │   └── flavor_config.dart   # Dev, Staging, Prod ortam değişkenleri
│       ├── di/
│       │   └── injection_container.dart # get_it servis locator kaydı (Tüm katmanlar)
│       ├── enums/
│       │   ├── user_role.dart       # student, teacher, admin rolleri
│       │   ├── attendance_status.dart # present, absent, late, excused
│       │   ├── submission_status.dart # onTime, late, graded, missing
│       │   ├── letter_grade.dart    # AA, BA, BB, CB, CC, DC, DD, FF (Katsayılar & Aralıklar)
│       │   └── announcement_type.dart # academic, social, emergency, club
│       ├── error/
│       │   ├── exceptions.dart      # ServerException, AuthException, RoleException, vb.
│       │   └── failures.dart        # ServerFailure, CacheFailure, ValidationFailure
│       ├── router/
│       │   ├── route_names.dart     # Sayfa rotası sabitleri (/login, /home, vb.)
│       │   ├── app_router.dart      # GoRouter yapılandırması & redirect mantığı
│       │   ├── role_guard.dart      # Öğrenci / Öğretmen rota koruma mekanizması
│       │   └── go_router_refresh_stream.dart # AuthState değişikliklerini dinleyen stream
│       └── utils/
│           ├── date_time_helper.dart # Tarih/saat formatlama ve zaman damgası yardımcıları
│           └── grade_calculator.dart # Kural 4 not hesaplama ve harf notu belirleme motoru
```

---

## 💻 3. Kullandığı Teknolojiler ve Paketler

| Teknoloji / Paket | Sürüm / Tür | Kullanım Amacı |
|---|---|---|
| **get_it** | DI (Dependency Injection) | Use Case, Repository, Data Source, Service ve Cubit sınıflarının gevşek bağlı (loosely coupled) kaydı ve singleton/factory enjeksiyonu. |
| **go_router** | Routing / Navigation | Declarative routing, ShellRoute (Bottom Navigation / Drawer senkronizasyonu), Nested Routing, Query/Path parametreleri. |
| **firebase_core** | Backend Platform | Uygulama başlangıcında Firebase platform servislerinin (`initializeApp`) başlatılması. |
| **firebase_crashlytics** | Monitoring / Telemetry | Fatal/non-fatal hataların ve UI exception'larının loglanması. |
| **flutter_bloc** | State Management | Router refresh stream'inde `AuthCubit` dinlenmesi ve global Provider enjeksiyonları. |
| **flutter_lints** | Kod Kalite Standartları | Analiz ve clean-code denetimleri (`analysis_options.yaml`). |

---

## ⚡ 4. Kritik İş Kuralları ve Çekirdek Görevler

### Kural 4: Not Ağırlıklandırma Motoru (`GradeCalculator`)
- Geliştirici 1, `lib/core/utils/grade_calculator.dart` dosyasını yönetir.
- **Formül:** `Başarı Notu = (Vize * 0.40) + (Final * 0.60) + Bonus Notu` (Tavan değer: 100).
- Harf Notu Skalası:
  - `90 - 100` : **AA** (4.0)
  - `85 - 89` : **BA** (3.5)
  - `80 - 84` : **BB** (3.0)
  - `75 - 79` : **CB** (2.5)
  - `70 - 74` : **CC** (2.0)
  - `65 - 69` : **DC** (1.5)
  - `60 - 64` : **DD** (1.0)
  - `0 - 59` : **FF** (0.0)

### Kural 5: Mutlak Rol Güvenliği (`RoleGuard` & `app_router.dart`)
- Yetkisiz erişimleri rota seviyesinde engeller.
- Eğer öğrenci rolündeki bir kullanıcı öğretmen rotalarına (`/attendance/qr-generator`, `/grade/entry`, `/assignment/create` vb.) doğrudan URL veya derin link (deep link) ile girmeye kalkışırsa, `RoleGuard` bunu tespit eder ve kullanıcıyı anında `/home` veya yetkisiz erişim ekranına yönlendirir.
- `GoRouterRefreshStream` ile `AuthCubit` durumu `Unauthenticated` olduğu anda kullanıcı tüm rotalardan çıkarılıp `/login` sayfasına yönlendirilir.

---

## 🏗️ 5. Diğer Geliştiricilerle İş Birliği Protokolü

1. **Geliştirici 3 (Firebase Lead) ile:**
   - Yeni bir Data Source veya Service eklendiğinde `injection_container.dart` içerisine `sl.registerLazySingleton<Type>(() => TypeImpl())` şeklinde kaydını ekleyin.
2. **Geliştirici 4 (Models/DTO Lead) ile:**
   - Yeni bir Entity ve Repository Interface'i tanımlandığında, Repository sözleşmesini DI konteynerine bağlayın.
3. **Geliştirici 5 (Logic/State Lead) ile:**
   - Yeni bir Use Case veya Cubit geliştirildiğinde, Use Case'i `sl.registerLazySingleton` veya Cubit'i `sl.registerFactory` olarak DI'a ekleyin.
4. **Geliştirici 6 (Screens Lead) ile:**
   - Yeni bir sayfa eklendiğinde `route_names.dart` içine rota adını ve `app_router.dart` içine GoRoute tanımını rol korumasıyla ekleyin.

---

## 📋 6. Kontrol Listesi (Checklist)

- [ ] `flutter pub get` hatasız çalışıyor mu?
- [ ] `flutter analyze` 0 hata ve 0 uyarı veriyor mu?
- [ ] Yeni eklenen servisler `injection_container.dart` içinde doğru sırayla (Core -> Data Sources -> Repositories -> Use Cases -> Cubits) kayıtlı mı?
- [ ] `RoleGuard` öğretmen ve öğrenci rolleri için beklenen rota korumasını sağlıyor mu?

