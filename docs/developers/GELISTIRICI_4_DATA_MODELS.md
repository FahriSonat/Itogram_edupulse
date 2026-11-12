# 📦 Geliştirici 4 Rehberi: Data Models & DTO Lead

Bu belge, **Geliştirici 4 (Data Models & DTO Lead)** rolünün görev alanını, sorumlu olduğu dosyaları, Clean Architecture Entity/DTO ayrımını ve veri modelleme standartlarını açıklar.

---

## 📌 1. Rol ve Misyon Özeti

- **Rol / Unvan:** Data Models, DTO & Domain Entities Lead
- **Temel Misyon:**
  - Uygulamanın tüm veri yapılarını Clean Architecture prensiplerine uygun olarak modellemek.
  - Domain katmanındaki saf iş nesnelerini (`Entity`) ile Data katmanındaki serileştirme modellerini (`Model`/`DTO`) birbirinden kesin çizgilerle ayırmak.
  - `fromJson`, `toJson`, `fromFirestore`, `toFirestore` dönüşümlerini eksiksiz, tip güvenli (type-safe) ve null-safe olarak inşa etmek.
  - Domain Repository Interface (Arayüz/Sözleşme) tanımlarını oluşturmak.
  - Firestore koleksiyon ve doküman yolu sabitlerini (`firestore_paths.dart`) yönetmek.

---

## 📂 2. Sorumlu Olduğu Dosya ve Klasörler

Geliştirici 4, Firestore yol sabitlerinden ve tüm modüllerin `domain/entities/`, `domain/repositories/` (arayüzler) ve `data/models/` (DTO) dosyalarından sorumludur:

```
itogram_edupulse/
└── lib/
    ├── core/constants/
    │   └── firestore_paths.dart     # Firestore koleksiyon ve alt koleksiyon yolları
    └── features/
        ├── auth/
        │   ├── domain/
        │   │   ├── entities/user_entity.dart
        │   │   └── repositories/auth_repository.dart
        │   └── data/models/user_model.dart
        ├── announcements/
        │   ├── domain/
        │   │   ├── entities/announcement_entity.dart
        │   │   └── repositories/announcement_repository.dart
        │   └── data/models/announcement_model.dart
        ├── schedule/
        │   ├── domain/
        │   │   ├── entities/course_schedule_entity.dart
        │   │   └── repositories/schedule_repository.dart
        │   └── data/models/course_schedule_model.dart
        ├── attendance/
        │   ├── domain/
        │   │   ├── entities/
        │   │   │   ├── attendance_session_entity.dart
        │   │   │   └── student_absence_record_entity.dart
        │   │   └── repositories/attendance_repository.dart
        │   └── data/models/
        │       ├── attendance_session_model.dart
        │       └── student_absence_record_model.dart
        ├── assignments/
        │   ├── domain/
        │   │   ├── entities/
        │   │   │   ├── assignment_entity.dart
        │   │   │   └── submission_entity.dart
        │   │   └── repositories/assignment_repository.dart
        │   └── data/models/
        │       ├── assignment_model.dart
        │       └── submission_model.dart
        ├── grades/
        │   ├── domain/
        │   │   ├── entities/course_grade_entity.dart
        │   │   └── repositories/grade_repository.dart
        │   └── data/models/course_grade_model.dart
        └── forum/
            ├── domain/
            │   ├── entities/
            │   │   ├── forum_question_entity.dart
            │   │   └── forum_answer_entity.dart
            │   └── repositories/forum_repository.dart
            └── data/models/
                ├── forum_question_model.dart
                └── forum_answer_model.dart
```

---

## 💻 3. Kullandığı Teknolojiler ve Paketler

| Teknoloji / Paket | Sürüm / Tür | Kullanım Amacı |
|---|---|---|
| **equatable** | Değer Eşitliği | Entity ve Model sınıflarının bellek referansına göre değil, içerdikleri alanlara (`props`) göre karşılaştırılabilmesi. |
| **cloud_firestore** (Timestamp / DocumentSnapshot) | Veri Dönüşümü | Firestore'dan gelen `Timestamp` türlerini Dart `DateTime` türlerine güvenli dönüştürme ve `DocumentSnapshot` okuması. |
| **Dart Core** | Type-Safety & Records | Null-safety, `copyWith` metodları, immutability (değişmezlik) prensipleri. |

---

## ⚡ 4. Kritik İş Kuralları ve Modelleme Standartları

### Kural 2: Ödev Teslim Modeli ve Ceza Alanları (`SubmissionModel`)
- `SubmissionEntity` ve `SubmissionModel`, geç teslim cezasını takip eden alanları içermelidir:
  ```dart
  class SubmissionModel extends SubmissionEntity {
    final String id;
    final String assignmentId;
    final String studentId;
    final String fileUrl;
    final DateTime submittedAt;
    final bool isLate;          // Teslim tarihinden sonra mı yüklendi?
    final double penaltyPoints; // Kural 2: Geç teslimse otomatik 10.0 ceza puanı
    final double? rawScore;     // Öğretmenin verdiği ham not (Örn: 85.0)
    final double? finalScore;   // rawScore - penaltyPoints (Örn: 75.0)
    final String? writtenFeedback;
    final String? audioFeedbackUrl;
    // ...
  }
  ```

### Kural 3: Devamsızlık Takip Modeli (`StudentAbsenceRecordModel`)
- Öğrencinin devamsızlık durumunu analiz etmek için modelde kritik hesaplama yardımcıları bulunmalıdır:
  ```dart
  class StudentAbsenceRecordModel extends StudentAbsenceRecordEntity {
    final String studentId;
    final String courseId;
    final int totalCourseHours;   // Toplam dönem ders saati (Örn: 56 saat)
    final int absentHours;         // Devamsızlık yapılan saat (Örn: 12 saat)
    
    double get absencePercentage => (absentHours / totalCourseHours) * 100;
    bool get isCriticalRisk => absencePercentage >= 20.0; // Kural 3 uyarınca %20 barajı
  }
  ```

### Kural 4: Not Modeli (`CourseGradeModel`)
- `CourseGradeModel`, Vize (%40), Final (%60) ve Bonus puanlarını tutar:
  ```dart
  class CourseGradeModel extends CourseGradeEntity {
    final String id;
    final String studentId;
    final String courseId;
    final double midtermScore;    // %40
    final double finalScore;      // %60
    final double bonusScore;      // Bonus
    final double calculatedTotal; // min(100.0, (midterm*0.4) + (final*0.6) + bonus)
    final LetterGrade letterGrade;// AA, BA, BB, ..., FF
  }
  ```

---

## 📐 5. Entity ve DTO Ayrımı Kuralı

- **Entity (Domain Katmanı):**
  - Kesinlikle `cloud_firestore` veya dış kütüphane bağımlılığı içermez (Sadece saf Dart ve `Equatable`).
  - Uygulamanın çekirdek iş mantığını temsil eder.
- **Model / DTO (Data Katmanı):**
  - İlgili Entity'den kalıtım alır (`extends XEntity`).
  - `factory XModel.fromFirestore(DocumentSnapshot doc)`
  - `Map<String, dynamic> toFirestore()`
  - `factory XModel.fromJson(Map<String, dynamic> json)`
  - `Map<String, dynamic> toJson()`
  - `XModel copyWith(...)`

---

## 📋 6. Kontrol Listesi (Checklist)

- [ ] Tüm Entity ve Model sınıflarında `Equatable` `props` listesi eksiksiz dolduruldu mu?
- [ ] Firestore `Timestamp` okurken null gelebilecek durumlar `(doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()` şeklinde güvenli hale getirildi mi?
- [ ] `firestore_paths.dart` içindeki koleksiyon isimleri küçük harfli ve tutarlı mı (`users`, `announcements`, `attendance_sessions`, `assignments`, vb.)?
- [ ] `copyWith` metodları tüm alanları doğru güncelliyor mu?

