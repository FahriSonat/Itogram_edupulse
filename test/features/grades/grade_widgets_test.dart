import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/enums/letter_grade.dart';
import 'package:itogram_edupulse/features/grades/presentation/widgets/course_grade_detail_card.dart';
import 'package:itogram_edupulse/features/grades/presentation/widgets/gpa_simulator_dashboard.dart';
import 'package:itogram_edupulse/features/grades/presentation/widgets/instructor_grade_entry_modal.dart';

import '../../helpers/design_test_harness.dart';

void main() {
  const students = <GradeEntryStudent>[
    (uid: 'u1', name: 'Ayşe Yılmaz', studentNo: '202604001'),
    (uid: 'u2', name: 'Mehmet Demir', studentNo: '202604002'),
  ];

  group('Kural 4 — Not Ağırlıklandırma önizlemesi', () {
    test('(Vize × 0.40) + (Final × 0.60) + Bonus, en fazla 100', () {
      expect(InstructorGradeEntryModal.previewTotal(midterm: 70, finalExam: 80), 76);
      expect(InstructorGradeEntryModal.previewTotal(midterm: 95, finalExam: 95, bonus: 15), 100);
      expect(InstructorGradeEntryModal.previewTotal(midterm: 0, finalExam: 0), 0);
    });

    test('harf notu baremi AA / BA / BB / FF', () {
      expect(InstructorGradeEntryModal.defaultLetterGrade(95), LetterGrade.AA);
      expect(InstructorGradeEntryModal.defaultLetterGrade(85), LetterGrade.BA);
      expect(InstructorGradeEntryModal.defaultLetterGrade(70), LetterGrade.BB);
      expect(InstructorGradeEntryModal.defaultLetterGrade(69.9), LetterGrade.FF);
    });

    test('0-100 not sınırı doğrulaması', () {
      expect(InstructorGradeEntryModal.validateScore('101'), AppStrings.scoreRangeError);
      expect(InstructorGradeEntryModal.validateScore(''), AppStrings.fieldRequired);
      expect(InstructorGradeEntryModal.validateScore('', required: false), isNull);
      expect(InstructorGradeEntryModal.validateScore('100'), isNull);
    });

    test('4.00\'lük katsayılar tüm harf notları için tanımlı', () {
      expect(LetterGrade.values.map(gradePointFor), [4.0, 3.5, 3.0, 2.5, 2.0, 1.5, 1.0, 0.5, 0.0, 0.0]);
    });
  });

  group('InstructorGradeEntryModal', () {
    testWidgets('sistemdeki öğrenci seçilir, canlı önizleme güncellenir ve kayıt uid ile yapılır', (tester) async {
      Map<String, Object>? saved;
      await pumpDesign(
        tester,
        InstructorGradeEntryModal(
          courseName: 'MOB101 • Flutter',
          students: students,
          onSave:
              ({
                required studentUid,
                required studentName,
                required studentNo,
                required midterm,
                required finalScore,
                required bonus,
                required total,
                required letterGrade,
              }) async {
                saved = {'uid': studentUid, 'name': studentName, 'total': total, 'letter': letterGrade};
              },
        ),
        scrollable: false,
      );

      await tester.tap(find.byKey(const ValueKey('grade_student_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mehmet Demir (202604002)').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('midterm_field')), '95');
      await tester.enterText(find.byKey(const ValueKey('final_field')), '95');
      await tester.enterText(find.byKey(const ValueKey('bonus_field')), '15');
      await tester.pump();
      expect(find.text('100.0'), findsOneWidget, reason: '95 + 15 bonus = 100 (tavan)');
      expect(find.text('Harf Notu: AA'), findsOneWidget);
      expect(find.textContaining('100\'e sabitlendi'), findsOneWidget);

      await tester.ensureVisible(find.text('Notu Sisteme İşle'));
      await tester.tap(find.text('Notu Sisteme İşle'));
      await tester.pump();
      expect(saved, {'uid': 'u2', 'name': 'Mehmet Demir', 'total': 100.0, 'letter': LetterGrade.AA});
    });

    testWidgets('özel letterGradeResolver ile dış hesaplayıcı bağlanabilir', (tester) async {
      await pumpDesign(
        tester,
        InstructorGradeEntryModal(
          courseName: 'MOB101',
          students: students,
          initialStudentUid: 'u1',
          initialMidterm: 60,
          initialFinal: 60,
          letterGradeResolver: (total) => total >= 60 ? LetterGrade.CC : LetterGrade.FF,
          onSave: ({
            required studentUid,
            required studentName,
            required studentNo,
            required midterm,
            required finalScore,
            required bonus,
            required total,
            required letterGrade,
          }) async {},
        ),
        scrollable: false,
      );
      expect(find.text('Harf Notu: CC'), findsOneWidget);
    });

    testWidgets('öğrenci seçilmeden veya 100 üstü notla kaydetmez', (tester) async {
      var called = false;
      await pumpDesign(
        tester,
        InstructorGradeEntryModal(
          courseName: 'MOB101',
          students: students,
          onSave: ({
            required studentUid,
            required studentName,
            required studentNo,
            required midterm,
            required finalScore,
            required bonus,
            required total,
            required letterGrade,
          }) async => called = true,
        ),
        scrollable: false,
      );
      await tester.enterText(find.byKey(const ValueKey('midterm_field')), '150');
      await tester.enterText(find.byKey(const ValueKey('final_field')), '80');
      await tester.ensureVisible(find.text('Notu Sisteme İşle'));
      await tester.tap(find.text('Notu Sisteme İşle'));
      await tester.pump();

      expect(called, isFalse);
      expect(find.text(AppStrings.studentSelectionRequired), findsOneWidget);
      expect(find.text(AppStrings.scoreRangeError), findsOneWidget);
    });

    testWidgets('düzenleme modunda öğrenci kilitli ve mevcut notlar dolu gelir', (tester) async {
      await pumpDesign(
        tester,
        InstructorGradeEntryModal(
          courseName: 'MOB101',
          students: students,
          initialStudentUid: 'u1',
          initialMidterm: 60,
          initialFinal: 80,
          onDelete: () {},
          onSave: ({
            required studentUid,
            required studentName,
            required studentNo,
            required midterm,
            required finalScore,
            required bonus,
            required total,
            required letterGrade,
          }) async {},
        ),
        scrollable: false,
      );
      expect(find.text('Notu Düzenle'), findsOneWidget);
      expect(find.text('Ayşe Yılmaz (202604001)'), findsOneWidget);
      expect(find.text('72.0'), findsOneWidget);
      expect(find.text('Harf Notu: BB'), findsOneWidget);
      expect(find.byTooltip('Notu Sil'), findsOneWidget);
      final dropdown = tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
      expect(dropdown.onChanged, isNull, reason: 'Düzenlemede öğrenci değiştirilemez');
    });
  });

  testWidgets('CourseGradeDetailCard renkli harf rozetini katsayıyla gösterir', (tester) async {
    var edited = false;
    await pumpDesign(
      tester,
      CourseGradeDetailCard(
        courseCode: 'MOB101',
        courseName: 'Flutter',
        credit: 6,
        midtermScore: 90,
        finalExamScore: 95,
        bonusScore: 5,
        totalAverage: 98,
        letterGrade: LetterGrade.AA,
        isInstructor: true,
        onEdit: () => edited = true,
      ),
    );
    expect(find.text('AA • 4.0'), findsOneWidget);
    expect(find.text('Vize (%40)'), findsOneWidget);
    expect(find.text('Final (%60)'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
    await tester.tap(find.text('Notu Düzenle'));
    expect(edited, isTrue);
  });

  testWidgets('GpaSimulatorDashboard 4.00 üzerinden göstergeyi çizer', (tester) async {
    var simulated = false;
    await pumpDesign(
      tester,
      GpaSimulatorDashboard(cumulativeGpa: 3.42, termGpa: 3.5, totalCredits: 24, onSimulateGpa: () => simulated = true),
    );
    expect(find.text('3.42'), findsOneWidget);
    expect(find.text('3.50'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(3.42 / 4, 0.0001));
    await tester.tap(find.text('Simülatör'));
    expect(simulated, isTrue);
  });

  testWidgets('not bileşenleri hiçbir ekran koşulunda taşmaz', (tester) async {
    await expectNoLayoutErrors(
      tester,
      () => const CourseGradeDetailCard(
        courseCode: 'MOB101',
        courseName: 'İleri Seviye Mobil Uygulama Geliştirme ve Yazılım Mimarisi',
        credit: 6,
        midtermScore: 100,
        finalExamScore: 100,
        bonusScore: 10,
        totalAverage: 100,
        letterGrade: LetterGrade.BA,
        isInstructor: true,
      ),
    );
    await expectNoLayoutErrors(
      tester,
      () => const GpaSimulatorDashboard(cumulativeGpa: 4, termGpa: 4, totalCredits: 240),
    );
    await expectNoLayoutErrors(
      tester,
      () => InstructorGradeEntryModal(
        courseName: 'MOB101 • Çok Uzun Ders Adı Örneği',
        students: students,
        initialStudentUid: 'u2',
        onDelete: () {},
        onSave: ({
          required studentUid,
          required studentName,
          required studentNo,
          required midterm,
          required finalScore,
          required bonus,
          required total,
          required letterGrade,
        }) async {},
      ),
      scrollable: false,
    );
  });
}

