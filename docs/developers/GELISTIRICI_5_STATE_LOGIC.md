# 🧠 Geliştirici 5 Rehberi: State & Logic Lead

Bu belge, **Geliştirici 5 (State & Logic Lead)** rolünün görev alanını, sorumlu olduğu dosyaları, BLoC/Cubit durum yönetimini, Use Case mimarisini ve asenkron/stream mantık standartlarını açıklar.

---

## 📌 1. Rol ve Misyon Özeti

- **Rol / Unvan:** State Management & Business Logic Lead
- **Temel Misyon:**
  - Projenin tüm iş mantığını (Business Logic) Clean Architecture `Use Case` sınıfları halinde soyutlamak.
  - Presentation katmanında `flutter_bloc` (Cubit) kullanarak reaktif ve öngörülebilir durum yönetimini sağlamak.
  - 60 saniyelik yoklama sayacı (`Timer.periodic`), canlı yoklama akışları (`StreamSubscription`), ödev yükleme ilerlemesi ve filtreleme durumlarını yönetmek.
  - Dart 3 pattern matching ve mühürlü sınıflar (`sealed class`) ile tip güvenli State hiyerarşisi oluşturmak.

---

## 📂 2. Sorumlu Olduğu Dosya ve Klasörler

Geliştirici 5, tüm modüllerin `domain/usecases/` klasörlerinden ve `presentation/cubit/` (Cubit + State) dosyalarından sorumludur:

```
itogram_edupulse/
└── lib/features/
    ├── auth/
    │   ├── domain/usecases/
    │   │   ├── login_use_case.dart
    │   │   ├── logout_use_case.dart
    │   │   └── get_current_user_use_case.dart
    │   └── presentation/cubit/
    │       ├── auth_cubit.dart
    │       └── auth_state.dart
    ├── announcements/
    │   ├── domain/usecases/
    │   │   ├── get_announcements_use_case.dart
    │   │   └── filter_announcements_use_case.dart
    │   └── presentation/cubit/
    │       ├── announcement_cubit.dart
    │       └── announcement_state.dart
    ├── schedule/
    │   ├── domain/usecases/
    │   │   └── get_course_schedule_use_case.dart
    │   └── presentation/cubit/
    │       ├── schedule_cubit.dart
    │       └── schedule_state.dart
    ├── attendance/
    │   ├── domain/usecases/
    │   │   ├── start_attendance_session_use_case.dart
    │   │   ├── submit_attendance_use_case.dart
    │   │   ├── get_attendance_stream_use_case.dart
    │   │   └── get_student_absence_records_use_case.dart
    │   └── presentation/cubit/
    │       ├── attendance_cubit.dart
    │       ├── attendance_state.dart
    │       ├── absence_cubit.dart
    │       └── absence_state.dart
    ├── assignments/
    │   ├── domain/usecases/
    │   │   ├── get_assignments_use_case.dart
    │   │   ├── submit_assignment_use_case.dart
    │   │   └── grade_submission_use_case.dart
    │   └── presentation/cubit/
    │       ├── assignment_cubit.dart
    │       └── assignment_state.dart
    ├── grades/
    │   ├── domain/usecases/
    │   │   ├── get_student_grades_use_case.dart
    │   │   ├── calculate_final_grade_use_case.dart
    │   │   └── simulate_target_gpa_use_case.dart
    │   └── presentation/cubit/
    │       ├── grade_cubit.dart
    │       └── grade_state.dart
    └── forum/
        ├── domain/usecases/
        │   ├── get_forum_questions_use_case.dart
        │   ├── ask_question_use_case.dart
        │   └── post_answer_use_case.dart
        └── presentation/cubit/
            ├── forum_cubit.dart
            └── forum_state.dart
```

---

## 💻 3. Kullandığı Teknolojiler ve Paketler

| Teknoloji / Paket | Sürüm / Tür | Kullanım Amacı |
|---|---|---|
| **flutter_bloc** | State Management | `Cubit` ve `BlocBuilder` / `BlocConsumer` / `BlocListener` ile reaktif UI senkronizasyonu. |
| **dart:async** | Stream & Timer | 60 saniyelik QR yenileme zamanlayıcısı (`Timer.periodic`), canlı Firestore dinlemeleri (`StreamSubscription`). |
| **fpdart / Either** (veya Result Pattern) | Fonksiyonel Hata Yönetimi | `Future<Either<Failure, T>>` dönüş tipiyle Use Case seviyesinde exception'ları failure'a dönüştürme. |
| **Dart 3 Sealed Classes** | State Modelleme | `sealed class AttendanceState {}` ve `on AttendanceLoaded`, `on AttendanceError` gibi pattern matching ile hatasız state tüketimi. |

---

## ⚡ 4. Kritik İş Kuralları ve Mantık Akışları

### Kural 1: 60 Sn Yoklama Zamanlayıcısı (`AttendanceCubit`)
- Öğretmen oturum başlattığında:
  ```dart
  void startSession(String courseId) {
    _timer?.cancel();
    _remainingSeconds = 60;
    _generateNewQrAndPin();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        _remainingSeconds--;
        emit(AttendanceSessionActive(qrCode: _currentQr, pin: _currentPin, remainingSeconds: _remainingSeconds));
      } else {
        // 60 saniye doldu -> Yeni QR & PIN üret ve sunucuya bildir
        _remainingSeconds = 60;
        _generateNewQrAndPin();
      }
    });
  }
  ```
- Cubit kapandığında (`close()`) mutlaka `_timer?.cancel()` ve `_streamSubscription?.cancel()` çağrılarak bellek sızıntısı engellenmelidir.

### Kural 2: Ödev Tesliminde Zaman Kontrolü ve Ceza (`SubmitAssignmentUseCase`)
- Öğrenci ödev yüklediğinde:
  - `now = DateTime.now()`
  - Eğer `now.isAfter(assignment.dueDate)` ise:
    - `isLate = true`
    - `penaltyPoints = 10.0`
    - Durum: `SubmissionStatus.late`
  - Eğer zamanında teslim edilmişse:
    - `isLate = false`
    - `penaltyPoints = 0.0`
    - Durum: `SubmissionStatus.onTime`
  - İşlem başarıyla tamamlandığında `emit(AssignmentSubmitSuccess(isLate: isLate))` yayınlanır.

### Kural 3: Devamsızlık Analizi ve Eşik Kontrolü (`AbsenceCubit`)
- Öğrencinin devamsızlık kayıtları geldiğinde:
  - `absencePercentage = (absentHours / totalHours) * 100`
  - Eğer `absencePercentage >= 20.0` ise state `AbsenceLoaded(isCritical: true, ...)` durumuna geçirilir.

### Kural 4: Not Simülasyonu Mantığı (`GradeCubit`)
- Öğrenci hedef harf notunu seçtiğinde (Örn: AA almak istiyor):
  - Gereken toplam not: 90.0
  - Vize: 70 (%40 = 28.0)
  - Kalan gereken: `90.0 - 28.0 = 62.0`
  - Finalden alması gereken: `62.0 / 0.60 = 103.3` -> "Final 100 üzerinden olduğu için AA alamazsınız!" uyarısı veya BA için gereken final notu hesaplanır.

---

## 📋 5. Kontrol Listesi (Checklist)

- [ ] Tüm Cubit sınıfları `super(InitialState())` ile doğru başlangıç durumu veriyor mu?
- [ ] Asenkron işlemlerde `emit()` çağrılmadan önce `if (isClosed) return;` kontrolü yapılıyor mu?
- [ ] Stream ve Timer referansları `close()` metodunda iptal (cancel) ediliyor mu?
- [ ] Tüm Use Case sınıfları tek bir işten sorumlu (`call` metodu) ve test edilebilir mi?

