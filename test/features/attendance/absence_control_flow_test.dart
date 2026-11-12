// Geliştirici 5 & 6 — 2.4 Devamsızlık Kontrol (Kural 3: %20 Kritik Risk).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/attendance_status.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/evaluate_absence_risk_usecase.dart';
import 'package:itogram_edupulse/features/attendance/presentation/cubit/absence_control_cubit.dart';
import 'package:itogram_edupulse/features/attendance/presentation/pages/absence_control_page.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/bell_curve_chart_painter.dart';
import 'package:itogram_edupulse/features/grades/domain/entities/course_grade_entity.dart';
import 'package:get_it/get_it.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/page_harness.dart';

CourseGradeEntity _grade(String uid, double mid, double fin) => CourseGradeEntity(
      gradeId: uid,
      courseId: 'c-mob',
      courseName: 'Mobil Programlama',
      credit: 3,
      studentUid: uid,
      studentName: uid,
      studentNo: '1',
      midtermScore: mid,
      finalScore: fin,
    );

void main() {
  group('EvaluateAbsenceRiskUseCase — %20 eşiği', () {
    test('tam %20 kritik risktir, altı değildir', () {
      expect(EvaluateAbsenceRiskUseCase.isCritical(8, 40), isTrue);
      expect(EvaluateAbsenceRiskUseCase.isCritical(7, 40), isFalse);
      expect(EvaluateAbsenceRiskUseCase.percentage(10, 40), 25);
      expect(EvaluateAbsenceRiskUseCase.percentage(3, 0), 0, reason: 'sıfıra bölme yok');
    });
  });

  group('AbsenceControlCubit', () {
    late TestBackend backend;
    setUp(() async {
      backend = TestBackend();
      await backend.register();
    });

    Future<void> flush() => Future<void>.delayed(const Duration(milliseconds: 10));

    test('öğrenci her dersten kendi devamsızlık kaydını alır', () async {
      backend.attendance.studentRecords['c-mob/uid-student'] = absenceRecord(courseId: 'c-mob', uid: 'uid-student', absent: 10);
      backend.attendance.studentRecords['c-alg/uid-student'] =
          absenceRecord(courseId: 'c-alg', uid: 'uid-student', absent: 2, courseName: 'Algoritmalar');
      final cubit = GetIt.instance<AbsenceControlCubit>()..loadForStudent('uid-student');
      await flush();

      expect(cubit.state.records.length, 2);
      expect(cubit.state.criticalRecords.single.courseId, 'c-mob');
      await cubit.close();
    });

    test('eğitmen: kırmızı liste en yüksek yüzdeden sıralanır, çan eğrisi hesaplanır', () async {
      backend.attendance.classRecords.items.addAll([
        absenceRecord(courseId: 'c-mob', uid: 'a', absent: 9, name: 'A'),
        absenceRecord(courseId: 'c-mob', uid: 'b', absent: 2, name: 'B'),
        absenceRecord(courseId: 'c-mob', uid: 'c', absent: 14, name: 'C'),
      ]);
      backend.grades.grades.items.addAll([_grade('a', 40, 60), _grade('b', 60, 80), _grade('c', 80, 100)]);
      final cubit = GetIt.instance<AbsenceControlCubit>()..loadForInstructor();
      await flush();

      expect(cubit.state.selectedCourseId, 'c-mob', reason: 'ilk ders otomatik seçilir');
      expect(cubit.state.criticalRecords.map((r) => r.studentUid), ['c', 'a']);
      expect(cubit.state.distribution.midtermAverage, 60);
      expect(cubit.state.distribution.finalAverage, 80);
      expect(cubit.state.distribution.midtermStd, closeTo(16.33, 0.01));
      expect(cubit.state.distribution.sampleSize, 3);
      await cubit.close();
    });

    test('manuel devamsızlık eklenince %20 riski yeniden hesaplanır (FCM tetiklenir)', () async {
      final cubit = GetIt.instance<AbsenceControlCubit>()..loadForInstructor();
      await flush();
      await cubit.markAttendance('uid-9', AttendanceStatus.absent);

      expect(backend.attendance.updates.single, ('c-mob', 'uid-9', AttendanceStatus.absent));
      expect(backend.attendance.evaluated, ['c-mob/uid-9']);
      await cubit.close();
    });

    test('distributionOf boş listede sıfır döner', () {
      final d = AbsenceControlCubit.distributionOf(const []);
      expect(d.sampleSize, 0);
      expect(d.midtermAverage, 0);
    });
  });

  group('AbsenceControlPage', () {
    late TestBackend backend;
    setUp(() async {
      backend = TestBackend();
      await backend.register();
    });

    testWidgets('öğrenci kritik risk uyarısını ve ders kartlarını görür', (tester) async {
      backend.attendance.studentRecords['c-mob/uid-student'] = absenceRecord(courseId: 'c-mob', uid: 'uid-student', absent: 10);
      await pumpPage(tester, const AbsenceControlPage(), backend: backend);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await settle(tester);

      expect(find.textContaining('Kritik Risk'), findsWidgets);
      expect(find.byType(BellCurveChartWidget), findsNothing, reason: 'çan eğrisi yalnızca eğitmende');
    });

    testWidgets('eğitmen çan eğrisini ve yoklama düzenleme menüsünü görür', (tester) async {
      backend.attendance.classRecords.items.add(absenceRecord(courseId: 'c-mob', uid: 'a', absent: 12, name: 'Ali'));
      await pumpPage(tester, const AbsenceControlPage(), backend: backend, role: UserRole.instructor);

      expect(find.byType(BellCurveChartWidget), findsOneWidget);
      await tester.scrollUntilVisible(find.byIcon(Icons.edit_calendar_rounded), 300, scrollable: find.byType(Scrollable).first);
      expect(find.byIcon(Icons.edit_calendar_rounded), findsOneWidget);
      expect(find.text('Ali'), findsWidgets, reason: 'kırmızı listede ve sınıf listesinde');
    });
  });
}
