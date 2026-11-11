import '../../../../core/enums/letter_grade.dart';
import '../../../../core/utils/grade_calculator.dart';
import '../entities/course_grade_entity.dart';

/// GPA özeti.
typedef GpaSummary = ({double cumulativeGpa, double termGpa, int totalCredits, int termCredits});

/// GPA simülatörü: mevcut notlardan kümülatif ve dönem GPA'sını hesaplar;
/// [overrides] ile "bu dersten AA alırsam?" senaryoları denenebilir.
class CalculateGpaSimulationUseCase {
  const CalculateGpaSimulationUseCase();

  /// [overrides]: ders kodu → varsayımsal harf notu.
  /// [extraCourses]: henüz notu girilmemiş derslerin (kredi, varsayımsal not) listesi.
  GpaSummary call(
    List<CourseGradeEntity> grades, {
    String currentTerm = CourseGradeEntity.currentTerm,
    Map<String, LetterGrade> overrides = const {},
    List<CreditGrade> extraCourses = const [],
  }) {
    final all = <CreditGrade>[];
    final term = <CreditGrade>[];
    for (final g in grades) {
      final letter = g.isCurrentTerm ? (overrides[g.courseCode] ?? g.letterGrade) : g.letterGrade;
      final entry = (credit: g.credit, grade: letter);
      all.add(entry);
      if (g.term == currentTerm) term.add(entry);
    }
    all.addAll(extraCourses);
    term.addAll(extraCourses);

    int credits(List<CreditGrade> list) => list.fold(0, (sum, c) => sum + c.credit);

    return (
      cumulativeGpa: GradeCalculator.calculateGpa(all),
      termGpa: GradeCalculator.calculateGpa(term),
      totalCredits: credits(all),
      termCredits: credits(term),
    );
  }
}
