// Geliştirici 5 & 6 — 2.5 Not Bilgisi (Kural 4: Vize %40 + Final %60 + Bonus, max 100).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:itogram_edupulse/core/enums/letter_grade.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/enums/view_status.dart';
import 'package:itogram_edupulse/features/grades/domain/entities/course_grade_entity.dart';
import 'package:itogram_edupulse/features/grades/domain/usecases/calculate_gpa_simulation_usecase.dart';
import 'package:itogram_edupulse/features/grades/domain/usecases/manage_student_grade_usecase.dart';
import 'package:itogram_edupulse/features/grades/presentation/cubit/grades_cubit.dart';
import 'package:itogram_edupulse/features/grades/presentation/pages/grade_info_page.dart';
import 'package:itogram_edupulse/features/grades/presentation/widgets/gpa_simulator_dashboard.dart';

import '../../helpers/page_harness.dart';

CourseGradeEntity _g(String courseId, int credit, LetterGrade letter, {String uid = 'uid-student'}) => CourseGradeEntity(
      gradeId: uid,
      courseId: courseId,
      courseName: courseId,
      credit: credit,
      studentUid: uid,
      studentName: 'Merve',
      studentNo: '20261234',
      midtermScore: 70,
      finalScore: 80,
      bonusScore: 0,
      totalAverage: 76,
      letterGrade: letter,
    );

const RegisteredStudent _merve = (uid: 'uid-student', name: 'Merve Kedersiz', studentNo: '20261234');

void main() {
  group('Kural 4 — ManageStudentGradeUseCase.buildGrade', () {
    test('Vize %40 + Final %60 + Bonus → ortalama ve harf notu', () {
      final g = ManageStudentGradeUseCase.buildGrade(
        courseId: 'c',
        courseName: 'c',
        credit: 3,
        student: _merve,
        midterm: 60,
        finalScore: 80,
        bonus: 5,
      );
      expect(g.totalAverage, closeTo(77, 1e-9));
      expect(g.letterGrade, LetterGrade.BA);
    });

    test('şartname örneği: 95 + 15 bonus = 100 (max) → AA', () {
      final g = ManageStudentGradeUseCase.buildGrade(
        courseId: 'c',
        courseName: 'c',
        credit: 3,
        student: _merve,
        midterm: 95,
        finalScore: 95,
        bonus: 15,
      );
      expect(g.totalAverage, 100);
      expect(g.letterGrade, LetterGrade.AA);
    });
  });

  group('CalculateGpaSimulationUseCase', () {
    const sim = CalculateGpaSimulationUseCase();

    test('kredi ağırlıklı GPA; notu girilmemiş ders sayılmaz', () {
      final grades = [
        _g('a', 4, LetterGrade.AA),
        _g('b', 3, LetterGrade.BB),
        const CourseGradeEntity(
          gradeId: 'x',
          courseId: 'c',
          courseName: 'c',
          credit: 5,
          studentUid: 'u',
          studentName: 'n',
          studentNo: '1',
        ),
      ];
      expect(sim(grades), 3.57);
      expect(sim.totalCredits(grades), 7);
    });

    test('simülasyon: BB alınan dersi AA yaparsam GPA 4.00 olur', () {
      final grades = [_g('a', 4, LetterGrade.AA), _g('b', 3, LetterGrade.BB)];
      expect(sim(grades, overrides: const {'b': LetterGrade.AA}), 4.0);
    });
  });

  group('GradesCubit', () {
    late TestBackend backend;
    late GradesCubit cubit;
    setUp(() async {
      backend = TestBackend();
      await backend.register();
      cubit = GetIt.instance<GradesCubit>();
    });
    tearDown(() => cubit.close());

    Future<void> flush() => Future<void>.delayed(const Duration(milliseconds: 10));

    test('öğrenci notları + GPA canlı hesaplanır; simülasyon sıfırlanabilir', () async {
      backend.grades.grades.items.addAll([_g('a', 4, LetterGrade.AA), _g('b', 3, LetterGrade.BB)]);
      cubit.loadForStudent('uid-student');
      await flush();
      expect(cubit.state.gpa, 3.57);
      expect(cubit.state.simulatedGpa, 3.57);

      cubit.simulate('b', LetterGrade.AA);
      expect(cubit.state.simulatedGpa, 4.0);
      expect(cubit.state.gpa, 3.57, reason: 'gerçek GPA değişmez');

      cubit.resetSimulation();
      expect(cubit.state.isSimulating, isFalse);
      expect(cubit.state.simulatedGpa, 3.57);
    });

    test('eğitmen: dersler + kayıtlı öğrenciler yüklenir, not kaydedilir ve silinir', () async {
      await cubit.loadForInstructor();
      await flush();
      expect(cubit.state.selectedCourseId, 'c-mob');
      expect(cubit.state.students.length, 2);

      expect(await cubit.saveGrade(student: _merve, midterm: 95, finalScore: 95, bonus: 15), isTrue);
      await flush();
      final saved = backend.grades.grades.items.single;
      expect(saved.totalAverage, 100);
      expect(saved.letterGrade, LetterGrade.AA);
      expect(cubit.state.grades.single.studentUid, 'uid-student');

      await cubit.deleteGrade(saved);
      await flush();
      expect(cubit.state.grades, isEmpty);
    });

    test('Vize 100\'den büyükse kayıt yapılmaz', () async {
      await cubit.loadForInstructor();
      await flush();
      expect(await cubit.saveGrade(student: _merve, midterm: 120, finalScore: 50, bonus: 0), isFalse);
      expect(backend.grades.grades.items, isEmpty);
    });

    test('akış hatasında failure', () async {
      backend.grades.grades.streamError = Exception('permission-denied');
      cubit.loadForStudent('uid-student');
      await flush();
      expect(cubit.state.status, ViewStatus.failure);
    });
  });

  group('GradeInfoPage', () {
    late TestBackend backend;
    setUp(() async {
      backend = TestBackend();
      await backend.register();
    });

    testWidgets('öğrenci GPA panelini görür, "Not Gir" butonu yoktur (Kural 5)', (tester) async {
      backend.grades.grades.items.add(_g('c-mob', 3, LetterGrade.BA));
      await pumpPage(tester, const GradeInfoPage(), backend: backend);
      expect(find.byType(GpaSimulatorDashboard), findsOneWidget);
      expect(find.byKey(const Key('grades_add')), findsNothing);
    });

    testWidgets('öğrenci notu yoksa boş durum görür', (tester) async {
      await pumpPage(tester, const GradeInfoPage(), backend: backend);
      expect(find.text('Henüz not girilmedi'), findsOneWidget);
    });

    testWidgets('eğitmen ders seçicisini ve "Not Gir" butonunu görür', (tester) async {
      await pumpPage(tester, const GradeInfoPage(), backend: backend, role: UserRole.instructor);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await settle(tester);
      expect(find.byKey(const Key('grades_add')), findsOneWidget);
      expect(find.text('Bu derste not yok'), findsOneWidget);
    });
  });
}
