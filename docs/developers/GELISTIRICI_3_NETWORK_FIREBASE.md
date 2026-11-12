# 🌐 Geliştirici 3 Rehberi: Network & Firebase Lead

Bu belge, **Geliştirici 3 (Network & Firebase Lead)** rolünün görev alanını, sorumlu olduğu dosyaları, Firebase/Cloud mimarisini ve donanım servisleri ile veri katmanı geliştirme standartlarını açıklar.

---

## 📌 1. Rol ve Misyon Özeti

- **Rol / Unvan:** Network, Firebase & Hardware Integration Lead
- **Temel Misyon:**
  - Firebase Authentication, Cloud Firestore ve Firebase Storage servislerinin entegrasyonunu sağlamak.
  - `firestore.rules` ve `storage.rules` güvenlik kurallarını yazmak ve güvenlik açıklarını önlemek.
  - FCM (Firebase Cloud Messaging) ve yerel bildirimleri (`flutter_local_notifications`) yapılandırmak.
  - Mikrofon (Ses kaydı) ve Dosya/Galeri seçici donanım servislerini geliştirmek.
  - Tüm modüllerin Remote Data Source'larını ve Data Repository implementasyonlarını yazarak veritabanı işlemlerini gerçekleştirmek.

---

## 📂 2. Sorumlu Olduğu Dosya ve Klasörler

Geliştirici 3, Firebase kök konfigürasyonlarından, servis entegrasyonlarından ve tüm `data/datasources/` ile `data/repositories/` dosyalarından sorumludur:

```
itogram_edupulse/
├── firestore.rules                  # Firestore güvenlik ve RBAC erişim kuralları
├── storage.rules                    # Firebase Storage yükleme ve izin kuralları
├── firebase.json                    # Firebase proje ve CLI deploy yapılandırması
└── lib/
    ├── core/
    │   ├── network/
    │   │   └── network_info.dart    # İnternet bağlantısı kontrolü (Connectivity Plus)
    │   └── services/
    │       ├── analytics_service.dart      # Firebase Analytics loglama servisi
    │       ├── audio_recorder_service.dart # Mikrofon ses kayıt servisi (record paketi)
    │       ├── fcm_notification_service.dart # Firebase Cloud Messaging push bildirim servisi
    │       ├── file_picker_service.dart    # PDF, dosya ve görsel seçici servis
    │       └── local_storage_service.dart  # SharedPreferences / Güvenli yerel önbellek
    └── features/
        ├── auth/data/
        │   ├── datasources/auth_remote_data_source.dart
        │   └── repositories/auth_repository_impl.dart
        ├── announcements/data/
        │   ├── datasources/announcement_remote_data_source.dart
        │   └── repositories/announcement_repository_impl.dart
        ├── schedule/data/
        │   ├── datasources/schedule_remote_data_source.dart
        │   └── repositories/schedule_repository_impl.dart
        ├── attendance/data/
        │   ├── datasources/attendance_remote_data_source.dart
        │   └── repositories/attendance_repository_impl.dart
        ├── assignments/data/
        │   ├── datasources/assignment_remote_data_source.dart
        │   └── repositories/assignment_repository_impl.dart
        ├── grades/data/
        │   ├── datasources/grade_remote_data_source.dart
        │   └── repositories/grade_repository_impl.dart
        └── forum/data/
            ├── datasources/forum_remote_data_source.dart
            └── repositories/forum_repository_impl.dart
```

---

## 💻 3. Kullandığı Teknolojiler ve Paketler

| Teknoloji / Paket | Sürüm / Tür | Kullanım Amacı |
|---|---|---|
| **firebase_auth** | Kimlik Doğrulama | Email/Şifre ile giriş, çıkış, parola sıfırlama ve mevcut kullanıcı oturum takibi. |
| **cloud_firestore** | NoSQL Veritabanı | Koleksiyon sorguları, gerçek zamanlı veri akışları (`snapshots()`), batch işlemler ve transaction'lar. |
| **firebase_storage** | Bulut Dosya Depolama | Ödev PDF dosyaları, soru ekleri ve sesli geri bildirimlerin (`.m4a`/`.mp3`) yüklenmesi ve indirme URL'si alınması. |
| **firebase_messaging** | Push Notifications | Arka plan ve ön plan anlık bildirimleri (FCM topic abonelikleri). |
| **flutter_local_notifications** | Yerel Bildirimler | Uygulama açıkken veya zamanlanmış yerel bildirim başlıklarının gösterilmesi. |
| **record** | Ses Donanımı | Öğretmenlerin sesli geri bildirim kaydetmesi ve foruma sesli yanıt eklenmesi için ses kaydı. |
| **file_picker / image_picker** | Dosya Donanımı | Kullanıcı cihazından PDF, görsel veya ödev dosyalarının seçilmesi. |
| **connectivity_plus** | Ağ Durumu | Cihazın Wi-Fi/Hücresel internet bağlantısının olup olmadığını kontrol etme. |

---

## ⚡ 4. Kritik İş Kuralları ve Güvenlik Altyapısı

### Kural 1: 60 Sn Dinamik Yoklama Altyapısı
- Öğretmen oturum başlattığında `attendance_sessions` koleksiyonunda yeni bir oturum açılır (`isActive: true`).
- Geliştirici 3, her oturum için `sessionToken` ve `pinCode` değerlerini güncelleyen veya doğrulayan remote data source metodunu sağlar:
  - `startAttendanceSession(sessionId, courseId, qrToken, pinCode)`
  - `submitAttendance(sessionId, studentId, qrToken, pinCode)`
- Öğrencinin yoklama kaydı transaction ile kontrol edilir: Süresi dolmuş token veya yanlış PIN ile gelen istekler `ServerException('Yoklama süresi doldu veya kod geçersiz!')` fırlatır.

### Kural 3: %20 Devamsızlık Uyarı Motoru ve Otomatik FCM Bildirimi
- `attendance_remote_data_source` veya repository katmanında, bir öğrencinin devamsızlığı `%20` barajını aştığı tespit edildiğinde:
  - `FCMNotificationService.sendAbsenceCriticalAlert(studentId, courseName, absencePercentage)` tetiklenir.
  - Bildirim başlığı: `"⚠️ Kritik Devamsızlık Uyarısı"`.
  - Bildirim içeriği: `"$courseName dersinde devamsızlığınız %$absencePercentage seviyesine ulaştı. Kalma riski!"`.

### Kural 5: Mutlak Rol Güvenliği (`firestore.rules` & `storage.rules`)
- İstemci tarafı bypass edilse bile veritabanını koruyan kurallar:
  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      function getUserRole() {
        return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
      }
      match /attendance_sessions/{sessionId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && getUserRole() == 'teacher';
      }
      match /assignments/{assignmentId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && getUserRole() == 'teacher';
      }
      match /grades/{gradeId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && getUserRole() == 'teacher';
      }
    }
  }
  ```
- Storage kurallarında ödev teslim dizinine (`submissions/{assignmentId}/{studentId}/*`) öğrenci sadece kendi dosyasını yükleyebilir.

---

## 📋 5. Kontrol Listesi (Checklist)

- [ ] Firebase bağlantısı koparsa `network_info.dart` durumu yakalayıp `NetworkFailure` döndürüyor mu?
- [ ] Ses kaydı (`audio_recorder_service`) mikrofon izni istiyor ve ses dosyasını Storage'a başarıyla yüklüyor mu?
- [ ] Dosya yükleme progress (yüzde) stream'i `assignments_remote_data_source` üzerinden UI'a aktarılabiliyor mu?
- [ ] Firestore ve Storage güvenlik kuralları yetkisiz yazma işlemlerini kesin olarak reddediyor mu?

