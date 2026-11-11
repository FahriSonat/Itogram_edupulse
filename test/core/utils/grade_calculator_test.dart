// Kural 2 & 4 Testi (Not Ağırlıklandırma Motoru ve Gecikme Cezası) — Geliştirici 6
// Test edilen kod: lib/core/utils/grade_calculator.dart (Geliştirici 1 & 5)
//
// - Başarı Notu = (Vize * 0.40) + (Final * 0.60) + Bonus, en fazla 100
//   (Şartname örneği: 95 + 15 Bonus = 100)
// - Gecikmiş ödevde -10 ceza puanı (minimum 0)
// - AA, BA, BB, FF harf notları ve 4.00 üzerinden GPA dönüşümü

import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/letter_grade.dart';
import 'package:itogram_edupulse/core/utils/grade_calculator.dart';

void main() {
  group('Kural 4 — calculateCourseAverage (Vize %40 + Final %60 + Bonus)', () {
    test('ağırlıklar doğru uygulanır', () {
      expect(GradeCalculator.calculateCourseAverage(50, 100, 0), closeTo(80, 1e-9));
      expect(GradeCalculator.calculateCourseAverage(100, 50, 0), closeTo(70, 1e-9));
      expect(GradeCalculator.calculateCourseAverage(60, 80, 0), closeTo(72, 1e-9));
    });

    test('bonus toplama eklenir', () {
      expect(GradeCalculator.calculateCourseAverage(60, 80, 5), closeTo(77, 1e-9));
    });

    test('şartname örneği: 95 ortalama + 15 bonus = 100 (100\'ü geçemez)', () {
      expect(GradeCalculator.calculateCourseAverage(95, 95, 15), 100.0);
    });

    test('tam puan + bonus yine 100\'e sabitlenir', () {
      expect(GradeCalculator.calculateCourseAverage(100, 100, 30), 100.0);
    });

    test('tam 100 olan sonuç değişmez', () {
      expect(GradeCalculator.calculateCourseAverage(100, 100, 0), 100.0);
    });

    test('sonuç 0\'ın altına düşmez', () {
      expect(GradeCalculator.calculateCourseAverage(0, 0, -5), 0.0);
    });

    test('ağırlık sabitleri şartnameyle aynıdır', () {
      expect(GradeCalculator.midtermWeight, 0.40);
      expect(GradeCalculator.finalWeight, 0.60);
      expect(GradeCalculator.maxScore, 100.0);
    });
  });

  group('Kural 2 — applyLatePenalty (-10 ceza puanı)', () {
    test('gecikmiş ödevden 10 puan düşer', () {
      expect(GradeCalculator.applyLatePenalty(85, true), 75);
    });

    test('zamanında teslim edilen ödevin puanı değişmez', () {
      expect(GradeCalculator.applyLatePenalty(85, false), 85);
    });

    test('ceza sonrası puan 0\'ın altına düşmez', () {
      expect(GradeCalculator.applyLatePenalty(6, true), 0);
      expect(GradeCalculator.applyLatePenalty(0, true), 0);
    });

    test('tam 10 puan alan geciken ödev 0 olur', () {
      expect(GradeCalculator.applyLatePenalty(10, true), 0);
    });

    test('ceza miktarı 10 puandır', () {
      expect(GradeCalculator.latePenaltyPoints, 10.0);
    });
  });

  group('getLetterGrade (AA, BA, BB, FF)', () {
    test('eşik değerleri ve sınırlar', () {
      expect(GradeCalculator.getLetterGrade(100), LetterGrade.AA);
      expect(GradeCalculator.getLetterGrade(85), LetterGrade.AA);
      expect(GradeCalculator.getLetterGrade(84.99), LetterGrade.BA);
      expect(GradeCalculator.getLetterGrade(70), LetterGrade.BA);
      expect(GradeCalculator.getLetterGrade(69.99), LetterGrade.BB);
      expect(GradeCalculator.getLetterGrade(50), LetterGrade.BB);
      expect(GradeCalculator.getLetterGrade(49.99), LetterGrade.FF);
      expect(GradeCalculator.getLetterGrade(0), LetterGrade.FF);
    });

    test('ortalama + harf notu birlikte: Vize 60, Final 80 → 72 → BA', () {
      final average = GradeCalculator.calculateCourseAverage(60, 80, 0);
      expect(GradeCalculator.getLetterGrade(average), LetterGrade.BA);
    });

    test('ödev cezası harf notunu düşürebilir: 88 → geç teslim 78 → BA', () {
      final penalized = GradeCalculator.applyLatePenalty(88, true);
      expect(GradeCalculator.getLetterGrade(88), LetterGrade.AA);
      expect(GradeCalculator.getLetterGrade(penalized), LetterGrade.BA);
    });
  });

  group('4.00 katsayıları ve calculateGPA', () {
    test('harf notu katsayıları şartnameyle aynıdır (AA 4.0, BA 3.5, BB 3.0, FF 0.0)', () {
      expect(LetterGrade.AA.coefficient, 4.0);
      expect(LetterGrade.BA.coefficient, 3.5);
      expect(LetterGrade.BB.coefficient, 3.0);
      expect(LetterGrade.FF.coefficient, 0.0);
    });

    test('kredi ağırlıklı ortalama hesaplanır', () {
      // (4 * 4.0 + 3 * 3.0) / 7 = 25 / 7 = 3.571... → 3.57
      final gpa = GradeCalculator.calculateGPA(<GradeEntry>[
        (credit: 4, letter: LetterGrade.AA),
        (credit: 3, letter: LetterGrade.BB),
      ]);
      expect(gpa, 3.57);
    });

    test('tüm dersler AA ise GPA 4.00', () {
      final gpa = GradeCalculator.calculateGPA(<GradeEntry>[
        (credit: 3, letter: LetterGrade.AA),
        (credit: 5, letter: LetterGrade.AA),
      ]);
      expect(gpa, 4.0);
    });

    test('FF olan ders ortalamayı krediye göre düşürür', () {
      // (2 * 4.0 + 2 * 0.0) / 4 = 2.00
      final gpa = GradeCalculator.calculateGPA(<GradeEntry>[
        (credit: 2, letter: LetterGrade.AA),
        (credit: 2, letter: LetterGrade.FF),
      ]);
      expect(gpa, 2.0);
    });

    test('boş liste veya toplam kredi 0 ise GPA 0 (sıfıra bölme yok)', () {
      expect(GradeCalculator.calculateGPA(<GradeEntry>[]), 0.0);
      expect(GradeCalculator.calculateGPA(<GradeEntry>[(credit: 0, letter: LetterGrade.AA)]), 0.0);
    });

    test('GPA hiçbir zaman 4.00\'ü geçmez', () {
      final gpa = GradeCalculator.calculateGPA(<GradeEntry>[
        for (var i = 0; i < 10; i++) (credit: 6, letter: LetterGrade.AA),
      ]);
      expect(gpa, lessThanOrEqualTo(4.0));
    });
  });

  group('LetterGrade enum', () {
    test('FF ve NA geçmez, diğerleri geçer', () {
      expect(LetterGrade.AA.isPassing, isTrue);
      expect(LetterGrade.BB.isPassing, isTrue);
      expect(LetterGrade.FF.isPassing, isFalse);
      expect(LetterGrade.NA.isPassing, isFalse);
    });

    test('toJson / fromJson tutarlıdır; bilinmeyen değer FF olur', () {
      for (final grade in LetterGrade.values) {
        expect(LetterGrade.fromJson(grade.toJson()), grade);
      }
      expect(LetterGrade.fromJson('XYZ'), LetterGrade.FF);
      expect(LetterGrade.fromJson(null), LetterGrade.FF);
    });
  });
}
