import 'dart:math' as math;

import '../enums/letter_grade.dart';

/// GPA hesabı için (kredi, harf notu) çifti.
typedef GradeEntry = ({double credit, LetterGrade letter});

/// Kural 2 ve Kural 4 motoru. Tüm metodlar saf (pure) ve statiktir.
class GradeCalculator {
  GradeCalculator._();

  static const double midtermWeight = 0.40;
  static const double finalWeight = 0.60;
  static const double maxScore = 100.0;
  static const double latePenaltyPoints = 10.0;

  // ---- Harf notu baremi ----
  // NOT: Şartnamede eşikler verilmemiş. Ekipçe teyit edilmeli.
  static const double thresholdAA = 85.0; // >= 85
  static const double thresholdBA = 70.0; // >= 70
  static const double thresholdBB = 50.0; // >= 50, altı FF

  /// Kural 4: (Vize * 0.40) + (Final * 0.60) + Bonus, en fazla 100.
  static double calculateCourseAverage(
    double midterm,
    double finalExam,
    double bonus,
  ) {
    final double raw =
        (midterm * midtermWeight) + (finalExam * finalWeight) + bonus;
    return raw.clamp(0.0, maxScore).toDouble();
  }

  /// Kural 2: Gecikmiş ödevde 10 puan düşer, minimum 0.
  static double applyLatePenalty(double score, bool isLate) {
    if (!isLate) return score;
    return math.max(0.0, score - latePenaltyPoints);
  }

  /// 0-100 arası puanı harf notuna çevirir.
  static LetterGrade getLetterGrade(double average) {
    if (average >= thresholdAA) return LetterGrade.AA;
    if (average >= thresholdBA) return LetterGrade.BA;
    if (average >= thresholdBB) return LetterGrade.BB;
    return LetterGrade.FF;
  }

  /// Kredi ağırlıklı GPA (4.00 üzerinden, 2 basamağa yuvarlanır).
  static double calculateGPA(List<GradeEntry> grades) {
    double totalCredits = 0;
    double totalPoints = 0;
    for (final GradeEntry g in grades) {
      totalCredits += g.credit;
      totalPoints += g.credit * g.letter.coefficient;
    }
    if (totalCredits == 0) return 0.0;
    return double.parse((totalPoints / totalCredits).toStringAsFixed(2));
  }
}
