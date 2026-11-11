import 'dart:math' as math;

import '../enums/letter_grade.dart';

/// GPA hesabında kullanılan tek ders kaydı (kredi + harf notu).
typedef CreditGrade = ({int credit, LetterGrade grade});

/// [GradeCalculator] Kural 4 (Not Ağırlıklandırma & GPA) ve Kural 2'nin
/// (Geç Teslim Cezası) saf hesaplama motorudur. Yan etkisi yoktur; unit
/// testlerle doğrulanır.
abstract final class GradeCalculator {
  static const double midtermWeight = 0.40;
  static const double finalWeight = 0.60;
  static const double maxScore = 100.0;
  static const double minScore = 0.0;

  /// Kural 2: Son teslim tarihinden sonra yapılan teslimlere uygulanan ceza.
  static const double latePenaltyPoints = 10.0;

  /// Başarı Notu = (Vize * 0.40) + (Final * 0.60) + Bonus — en fazla 100.
  static double calculateTotal({required double midterm, required double finalExam, double bonus = 0}) {
    final raw = (midterm * midtermWeight) + (finalExam * finalWeight) + bonus;
    return _round2(raw.clamp(minScore, maxScore).toDouble());
  }

  static LetterGrade letterFor(double total) => LetterGrade.fromScore(total);

  /// Kredi ağırlıklı ortalama (4.00 üzerinden). Ders yoksa 0 döner.
  static double calculateGpa(Iterable<CreditGrade> courses) {
    var totalCredits = 0;
    var weighted = 0.0;
    for (final c in courses) {
      if (c.credit <= 0) continue;
      totalCredits += c.credit;
      weighted += c.credit * c.grade.coefficient;
    }
    if (totalCredits == 0) return 0;
    return _round2(weighted / totalCredits);
  }

  /// Kural 2: Geç teslimde ham puandan 10 puan düşülür (0'ın altına inmez).
  static double applyLatePenalty(double score, {required bool isLate}) {
    if (!isLate) return score;
    return math.max(minScore, score - latePenaltyPoints);
  }

  static bool isValidScore(double? score) => score != null && score >= minScore && score <= maxScore;

  static double mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Popülasyon standart sapması. Tek değer veya boş listede 0 döner.
  static double standardDeviation(List<double> values) {
    if (values.length < 2) return 0;
    final m = mean(values);
    final variance = values.map((v) => math.pow(v - m, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
