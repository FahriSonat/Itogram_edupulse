import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/letter_grade.dart';
import 'package:itogram_edupulse/core/utils/grade_calculator.dart';

void main() {
  group('Kural 4 — Başarı notu (Vize %40 + Final %60 + Bonus, max 100)', () {
    test('ağırlıklı ortalamayı hesaplar', () {
      expect(GradeCalculator.calculateTotal(midterm: 85, finalExam: 92, bonus: 5), 94.2);
      expect(GradeCalculator.calculateTotal(midterm: 70, finalExam: 78), 74.8);
    });

    test('100 puanı aşamaz, 0 altına inmez', () {
      expect(GradeCalculator.calculateTotal(midterm: 100, finalExam: 100, bonus: 15), 100);
      expect(GradeCalculator.calculateTotal(midterm: 0, finalExam: 0, bonus: -5), 0);
    });

    test('sınır değerlerde doğru harf notunu verir', () {
      expect(GradeCalculator.letterFor(GradeCalculator.calculateTotal(midterm: 90, finalExam: 90)), LetterGrade.AA);
      expect(GradeCalculator.letterFor(89.99), LetterGrade.BA);
      expect(GradeCalculator.letterFor(80), LetterGrade.BA);
      expect(GradeCalculator.letterFor(70), LetterGrade.BB);
      expect(GradeCalculator.letterFor(69.9), LetterGrade.FF);
    });
  });

  group('GPA', () {
    test('kredi ağırlıklı ortalama', () {
      final gpa = GradeCalculator.calculateGpa([
        (credit: 6, grade: LetterGrade.AA),
        (credit: 5, grade: LetterGrade.BB),
        (credit: 4, grade: LetterGrade.BA),
        (credit: 3, grade: LetterGrade.BA),
      ]);
      // (24 + 15 + 14 + 10.5) / 18 = 3.527…
      expect(gpa, 3.53);
    });

    test('ders yoksa 0 döner', () {
      expect(GradeCalculator.calculateGpa(const []), 0);
    });
  });

  group('Kural 2 — Geç teslim cezası', () {
    test('geç teslimde 10 puan düşer', () {
      expect(GradeCalculator.applyLatePenalty(84, isLate: true), 74);
      expect(GradeCalculator.applyLatePenalty(84, isLate: false), 84);
    });

    test('ceza puanı 0 altına indirmez', () {
      expect(GradeCalculator.applyLatePenalty(6, isLate: true), 0);
    });
  });

  test('ortalama ve standart sapma', () {
    expect(GradeCalculator.mean([70, 80, 90]), 80);
    expect(GradeCalculator.standardDeviation([70, 80, 90]), closeTo(8.165, 0.001));
    expect(GradeCalculator.standardDeviation([75]), 0);
  });
}
