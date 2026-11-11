import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/features/attendance/data/models/student_absence_record_model.dart';
import 'package:itogram_edupulse/features/attendance/domain/entities/student_absence_record_entity.dart';

void main() {
  const StudentAbsenceRecordModel model = StudentAbsenceRecordModel(
    studentUid: 'uid-1',
    studentName: 'Merve Kedersiz',
    studentNo: '20261234',
    courseId: 'course-101',
    courseName: 'Mobil Programlama',
    totalCourseHours: 56,
    absentHours: 12,
    absencePercentage: 21.43,
    isCriticalRisk: true,
  );

  final Map<String, dynamic> json = <String, dynamic>{
    'studentName': 'Merve Kedersiz',
    'studentNo': '20261234',
    'courseId': 'course-101',
    'courseName': 'Mobil Programlama',
    'totalCourseHours': 56,
    'absentHours': 12,
    'absencePercentage': 21.43,
    'isCriticalRisk': true,
  };

  group('StudentAbsenceRecordModel', () {
    test('StudentAbsenceRecordEntity alt sınıfıdır', () {
      expect(model, isA<StudentAbsenceRecordEntity>());
    });

    test('fromFirestore tüm alanları doğru okur', () {
      expect(StudentAbsenceRecordModel.fromFirestore(json, 'uid-1'), model);
    });

    test('toJson doğru map üretir', () {
      expect(model.toJson(), json);
    });

    test('toJson -> fromFirestore aynı nesneyi verir', () {
      expect(
        StudentAbsenceRecordModel.fromFirestore(model.toJson(), model.studentUid),
        model,
      );
    });

    test('Kural 3: kritik risk bayrağı korunur', () {
      expect(
        StudentAbsenceRecordModel.fromFirestore(model.toJson(), 'uid-1')
            .isCriticalRisk,
        isTrue,
      );
    });

    test('Firestore yüzdeyi int döndürse de double okunur', () {
      final Map<String, dynamic> intPercent = Map<String, dynamic>.of(json)
        ..['absencePercentage'] = 20;
      expect(
        StudentAbsenceRecordModel.fromFirestore(intPercent, 'uid-1')
            .absencePercentage,
        20.0,
      );
    });

    test('isCriticalRisk yoksa false olur', () {
      final Map<String, dynamic> noFlag = Map<String, dynamic>.of(json)
        ..remove('isCriticalRisk');
      expect(
        StudentAbsenceRecordModel.fromFirestore(noFlag, 'uid-1').isCriticalRisk,
        isFalse,
      );
    });

    test('copyWith sadece verilen alanı değiştirir', () {
      final StudentAbsenceRecordModel updated = model.copyWith(absentHours: 4);
      expect(updated.absentHours, 4);
      expect(updated.totalCourseHours, model.totalCourseHours);
      expect(updated.copyWith(absentHours: 12), model);
    });
  });
}
