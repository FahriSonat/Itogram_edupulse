import '../../../../core/enums/letter_grade.dart';
import '../../../../core/utils/grade_calculator.dart';
import '../entities/course_grade_entity.dart';

/// Öğrencinin gerçek ve "şu notu alırsam" simülasyonlu GPA'sı (4.00 üzerinden).
class CalculateGpaSimulationUseCase {
  const CalculateGpaSimulationUseCase();

  /// Kredi ağırlıklı GPA. [overrides] ile ders bazında (courseId → harf)
  /// varsayımsal not verilebilir. Harf notu olmayan / NA dersler sayılmaz.
  double call(List<CourseGradeEntity> grades, {Map<String, LetterGrade> overrides = const {}}) {
    final entries = <GradeEntry>[];
    for (final g in grades) {
      final letter = overrides[g.courseId] ?? g.letterGrade;
      if (letter == null || letter == LetterGrade.NA) continue;
      entries.add((credit: g.credit.toDouble(), letter: letter));
    }
    return GradeCalculator.calculateGPA(entries);
  }

  int totalCredits(List<CourseGradeEntity> grades) =>
      grades.where((g) => g.letterGrade != null).fold<int>(0, (sum, g) => sum + g.credit);
}
