import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/enums/attendance_status.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/bell_curve_chart_painter.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/critical_absence_red_list.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/dynamic_qr_pin_board.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/live_attendance_roster_tabs.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/student_absence_progress_card.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/student_qr_pin_scanner.dart';

import '../../helpers/design_test_harness.dart';

void main() {
  group('DynamicQrPinBoard (Kural 1 — 60 sn QR/PIN)', () {
    testWidgets('token\'dan QR matrisi çizer ve 4 haneli PIN\'i gösterir', (tester) async {
      await pumpDesign(tester, const DynamicQrPinBoard(pinCode: '4821', qrToken: 'session_42_token'));

      expect(find.bySemanticsLabel('Yoklama QR kodu'), findsOneWidget);
      expect(find.byKey(const ValueKey('qr_session_42_token')), findsOneWidget);
      for (final digit in ['4', '8', '2', '1']) {
        expect(find.text(digit), findsOneWidget);
      }
      expect(find.text('60 sn'), findsOneWidget);
    });

    testWidgets('60 saniye dolunca onExpireOrRefresh bir kez çağrılır', (tester) async {
      var refreshed = 0;
      await pumpDesign(tester, DynamicQrPinBoard(pinCode: '1234', qrToken: 't', onExpireOrRefresh: () => refreshed++));
      await tester.pump(const Duration(seconds: 59));
      expect(refreshed, 0);
      expect(find.text('1 sn'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(refreshed, 1);
      expect(find.text('Yenileniyor...'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      expect(refreshed, 1);
    });
  });

  group('StudentQrPinScanner', () {
    testWidgets('4. hane girilince PIN otomatik doğrulanır', (tester) async {
      String? submitted;
      await pumpDesign(
        tester,
        StudentQrPinScanner(onSubmitPin: (pin) async => submitted = pin, onOpenQrScanner: () {}),
      );
      await tester.enterText(find.byKey(const ValueKey('pin_input_field')), '7391');
      await tester.pump();
      expect(submitted, '7391');
    });

    testWidgets('süresi dolmuş kod hatası kutuların altında gösterilir', (tester) async {
      await pumpDesign(
        tester,
        StudentQrPinScanner(
          onSubmitPin: (_) async => throw Exception(AppStrings.qrExpiredError),
          onOpenQrScanner: () {},
        ),
      );
      await tester.enterText(find.byKey(const ValueKey('pin_input_field')), '1111');
      await tester.pump();
      await tester.pump();
      expect(find.text(AppStrings.qrExpiredError), findsOneWidget);
    });

    testWidgets('eksik PIN ile doğrulama uyarı verir, QR butonu callback\'i tetikler', (tester) async {
      var submitted = false;
      var opened = false;
      await pumpDesign(
        tester,
        StudentQrPinScanner(onSubmitPin: (_) async => submitted = true, onOpenQrScanner: () => opened = true),
      );
      await tester.enterText(find.byKey(const ValueKey('pin_input_field')), '12');
      await tester.tap(find.text('Kodu Doğrula'));
      await tester.pump();
      expect(submitted, isFalse);
      expect(find.text(AppStrings.pinCodeLengthError), findsOneWidget);

      await tester.tap(find.text('QR Okut'));
      expect(opened, isTrue);
    });

    testWidgets('yalnızca rakam kabul edilir', (tester) async {
      String? submitted;
      await pumpDesign(tester, StudentQrPinScanner(onSubmitPin: (p) async => submitted = p, onOpenQrScanner: null));
      await tester.enterText(find.byKey(const ValueKey('pin_input_field')), '12ab34');
      await tester.pump();
      expect(submitted, '1234');
      expect(find.text('QR Okut'), findsNothing);
    });
  });

  group('LiveAttendanceRosterTabs', () {
    final attendees = [
      const AttendeeItem(studentUid: 'a', studentName: 'Ali', studentNo: '1', status: AttendanceStatus.present),
      const AttendeeItem(studentUid: 'e', studentName: 'Ece', studentNo: '5', status: AttendanceStatus.late),
      const AttendeeItem(studentUid: 'b', studentName: 'Berk', studentNo: '2', status: AttendanceStatus.absent),
      const AttendeeItem(studentUid: 'c', studentName: 'Can', studentNo: '3', status: AttendanceStatus.absent),
      const AttendeeItem(studentUid: 'd', studentName: 'Deniz', studentNo: '4', status: AttendanceStatus.excused),
    ];

    testWidgets('Gelen / Geç Kalan / Gelmeyen / İzinli sekmeleri sayılarla görünür', (tester) async {
      await pumpDesign(tester, LiveAttendanceRosterTabs(attendees: attendees));
      expect(find.text('Gelen (1)'), findsOneWidget);
      expect(find.text('Geç Kalan (1)'), findsOneWidget);
      expect(find.text('Gelmeyen (2)'), findsOneWidget);
      expect(find.text('İzinli (1)'), findsOneWidget);
      expect(find.text('Ali'), findsOneWidget);

      await tester.tap(find.text('Geç Kalan (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Ece'), findsOneWidget);

      await tester.tap(find.text('Gelmeyen (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Berk'), findsOneWidget);
      expect(find.text('Can'), findsOneWidget);
    });

    testWidgets('eğitmen durumu değiştirebilir', (tester) async {
      AttendanceStatus? changed;
      await pumpDesign(tester, LiveAttendanceRosterTabs(attendees: attendees, onStatusChanged: (_, s) => changed = s));
      await tester.tap(find.byTooltip('Durumu değiştir').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('İzinli Yap'));
      await tester.pumpAndSettle();
      expect(changed, AttendanceStatus.excused);
    });
  });

  group('Kural 3 — %20 devamsızlık', () {
    test('CriticalAbsenceItem %20 ve üzerini Kritik Risk sayar', () {
      CriticalAbsenceItem item(int absent) => CriticalAbsenceItem(
        studentUid: 'u',
        studentName: 'Ö',
        studentNo: '1',
        courseName: 'Flutter',
        absentHours: absent,
        totalCourseHours: 40,
      );
      expect(item(7).isCriticalRisk, isFalse);
      expect(item(7).isApproaching, isTrue);
      expect(item(8).isCriticalRisk, isTrue);
      expect(item(8).absencePercentage, 20);
      expect(item(2).isApproaching, isFalse);
    });

    testWidgets('kırmızı liste kritikleri yüzdeye göre sıralar, güvendekileri gizler', (tester) async {
      await pumpDesign(
        tester,
        CriticalAbsenceRedList(
          atRiskStudents: [
            CriticalAbsenceItem(
              studentUid: '1',
              studentName: 'Güvende Öğrenci',
              studentNo: '1',
              courseName: 'C',
              absentHours: 1,
              totalCourseHours: 40,
            ),
            CriticalAbsenceItem(
              studentUid: '2',
              studentName: 'Yaklaşan Öğrenci',
              studentNo: '2',
              courseName: 'C',
              absentHours: 7,
              totalCourseHours: 40,
            ),
            CriticalAbsenceItem(
              studentUid: '3',
              studentName: 'Riskli Öğrenci',
              studentNo: '3',
              courseName: 'C',
              absentHours: 12,
              totalCourseHours: 40,
            ),
          ],
          onSendPushWarning: (_) {},
        ),
      );
      expect(find.text('Güvende Öğrenci'), findsNothing);
      expect(find.text('Sınıra yaklaşıyor'), findsOneWidget);
      final risky = tester.getTopLeft(find.text('Riskli Öğrenci')).dy;
      final approaching = tester.getTopLeft(find.text('Yaklaşan Öğrenci')).dy;
      expect(risky, lessThan(approaching), reason: 'En yüksek devamsızlık en üstte');
    });

    testWidgets('riskli öğrenci yoksa tebrik mesajı gösterilir', (tester) async {
      await pumpDesign(tester, const CriticalAbsenceRedList(atRiskStudents: []));
      expect(find.textContaining('Tebrikler'), findsOneWidget);
    });

    testWidgets('StudentAbsenceProgressCard tam %20\'de Kritik Risk gösterir', (tester) async {
      await pumpDesign(
        tester,
        const StudentAbsenceProgressCard(courseName: 'Flutter', totalCourseHours: 40, absentHours: 8),
      );
      expect(find.text('Kritik Risk (%20+)'), findsOneWidget);
      expect(find.text('%20.0'), findsOneWidget);

      await pumpDesign(
        tester,
        const StudentAbsenceProgressCard(courseName: 'Flutter', totalCourseHours: 40, absentHours: 3),
      );
      expect(find.text('Güvende'), findsOneWidget);
      expect(find.text('Sınıra kadar kalan hak: 5 saat'), findsOneWidget);
    });
  });

  group('Vize-Final Çan Eğrisi (CustomPainter)', () {
    test('BellCurveSeries.fromScores ortalama ve standart sapmayı hesaplar', () {
      final s = BellCurveSeries.fromScores(label: 'Vize', scores: [60, 70, 80], color: Colors.blue);
      expect(s.mean, 70);
      expect(s.standardDeviation, closeTo(8.165, 0.001));
      expect(s.density(70), greaterThan(s.density(90)));
    });

    test('sapma 0 olduğunda çizim için yedek sapma kullanılır, ortalama 0-100\'e sabitlenir', () {
      const s = BellCurveSeries(label: 'Final', mean: 120, standardDeviation: 0, color: Colors.red);
      expect(s.effectiveDeviation, BellCurveSeries.fallbackDeviation);
      expect(s.clampedMean, 100);
    });

    testWidgets('widget iki eğriyi (Vize ve Final) ve ortalamaları çizer', (tester) async {
      await pumpDesign(
        tester,
        BellCurveChartWidget.fromScores(
          midtermScores: const [55, 65, 75, 85],
          finalScores: const [60, 70, 80, 95],
          studentMidterm: 75,
          studentFinal: 80,
        ),
      );
      final paint = tester.widget<CustomPaint>(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is BellCurveChartPainter),
      );
      final painter = paint.painter! as BellCurveChartPainter;
      expect(painter.series.map((s) => s.label), ['Vize', 'Final']);
      expect(find.text('Vize Ort.: 70.0'), findsOneWidget);
      expect(find.text('Final Ort.: 76.3'), findsOneWidget);
      expect(find.text('4 öğrenci'), findsOneWidget);
      expect(BellCurveChartPainter.gradeLabels, ['FF', 'BB', 'BA', 'AA']);
    });
  });

  testWidgets('yoklama bileşenleri hiçbir ekran koşulunda taşmaz', (tester) async {
    await expectNoLayoutErrors(tester, () => const DynamicQrPinBoard(pinCode: '4821', qrToken: 'token'));
    await expectNoLayoutErrors(tester, () => StudentQrPinScanner(onSubmitPin: (_) async {}, onOpenQrScanner: () {}));
    await expectNoLayoutErrors(
      tester,
      () => const StudentAbsenceProgressCard(
        courseName: 'Çok Uzun Ders Adı: İleri Seviye Mobil Uygulama Geliştirme',
        totalCourseHours: 56,
        absentHours: 13,
      ),
    );
    await expectNoLayoutErrors(
      tester,
      () => CriticalAbsenceRedList(
        atRiskStudents: [
          CriticalAbsenceItem(
            studentUid: '1',
            studentName: 'Uzun İsimli Öğrenci Adı Soyadı Örneği',
            studentNo: '202604001',
            courseName: 'Veri Yapıları ve Algoritmalar',
            absentHours: 14,
            totalCourseHours: 56,
          ),
        ],
        onSendPushWarning: (_) {},
      ),
    );
    await expectNoLayoutErrors(
      tester,
      () => BellCurveChartWidget.fromScores(midtermScores: const [40, 90], finalScores: const [50, 100]),
    );
  });
}

