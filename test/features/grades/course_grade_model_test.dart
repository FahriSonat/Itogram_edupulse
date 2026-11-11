import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/letter_grade.dart';
import 'package:itogram_edupulse/features/grades/data/models/course_grade_model.dart';
import 'package:itogram_edupulse/features/grades/domain/entities/course_grade_entity.dart';

void main() {
  const CourseGradeModel model = CourseGradeModel(
    gradeId: 'grade-1',
    courseId: 'course-101',
    courseName: 'Mobil Programlama',
    credit: 4,
    studentUid: 'uid-1',
    studentName: 'Merve Kedersiz',
    studentNo: '20261234',
    midtermScore: 80,
    finalScore: 90,
    bonusScore: 5,
    totalAverage: 91,
    letterGrade: LetterGrade.AA,
  );

  final Map<String, dynamic> json = <String, dynamic>{
    'courseId': 'course-101',
    'courseName': 'Mobil Programlama',
    'credit': 4,
    'studentUid': 'uid-1',
    'studentName': 'Merve Kedersiz',
    'studentNo': '20261234',
    'midtermScore': 80.0,
    'finalScore': 90.0,
    'bonusScore': 5.0,
    'totalAverage': 91.0,
    'letterGrade': 'AA',
  };

  group('CourseGradeModel', () {
    test('CourseGradeEntity alt sınıfıdır', () {
      expect(model, isA<CourseGradeEntity>());
    });

    test('fromFirestore tüm alanları doğru okur', () {
      expect(CourseGradeModel.fromFirestore(json, 'grade-1'), model);
    });

    test('toJson doğru map üretir', () {
      expect(model.toJson(), json);
    });

    test('toJson -> fromFirestore aynı nesneyi verir', () {
      expect(CourseGradeModel.fromFirestore(model.toJson(), model.gradeId), model);
    });

    test('Firestore int not döndürse de double olarak okunur', () {
      final Map<String, dynamic> intScores = Map<String, dynamic>.of(json)
        ..['midtermScore'] = 80
        ..['finalScore'] = 90;
      final CourseGradeModel parsed =
          CourseGradeModel.fromFirestore(intScores, 'grade-1');
      expect(parsed.midtermScore, 80.0);
      expect(parsed.finalScore, 90.0);
    });

    test('henüz girilmemiş notlar ve harf notu null olur', () {
      final Map<String, dynamic> empty = Map<String, dynamic>.of(json)
        ..remove('midtermScore')
        ..remove('finalScore')
        ..remove('bonusScore')
        ..remove('totalAverage')
        ..remove('letterGrade');
      final CourseGradeModel parsed =
          CourseGradeModel.fromFirestore(empty, 'grade-1');
      expect(parsed.midtermScore, isNull);
      expect(parsed.finalScore, isNull);
      expect(parsed.bonusScore, isNull);
      expect(parsed.totalAverage, isNull);
      expect(parsed.letterGrade, isNull);
      expect(parsed.toJson()['letterGrade'], isNull);
    });

    test('şartnamedeki harf notları (AA, BA, BB, FF) okunup yazılabilir', () {
      for (final LetterGrade grade in <LetterGrade>[
        LetterGrade.AA,
        LetterGrade.BA,
        LetterGrade.BB,
        LetterGrade.FF,
      ]) {
        final CourseGradeModel m = model.copyWith(letterGrade: grade);
        expect(
          CourseGradeModel.fromFirestore(m.toJson(), m.gradeId).letterGrade,
          grade,
        );
      }
    });

    test('bilinmeyen harf notu uygulamayı çökertmemeli', () {
      final Map<String, dynamic> bad = Map<String, dynamic>.of(json)
        ..['letterGrade'] = 'XX';
      expect(
        () => CourseGradeModel.fromFirestore(bad, 'grade-1'),
        returnsNormally,
      );
    });

    test('copyWith sadece verilen alanı değiştirir', () {
      final CourseGradeModel updated = model.copyWith(bonusScore: 10);
      expect(updated.bonusScore, 10);
      expect(updated.midtermScore, model.midtermScore);
      expect(updated.copyWith(bonusScore: 5), model);
    });
  });
}
