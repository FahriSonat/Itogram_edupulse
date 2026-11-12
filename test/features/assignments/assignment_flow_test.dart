// Geliştirici 5 & 6 — 2.3 Ödev Kontrol (Kural 2: Gecikmiş teslim -10 ceza).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:itogram_edupulse/core/enums/submission_status.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/features/assignments/domain/entities/assignment_entity.dart';
import 'package:itogram_edupulse/features/assignments/domain/usecases/grade_and_feedback_usecase.dart';
import 'package:itogram_edupulse/features/assignments/domain/usecases/upload_assignment_submission_usecase.dart';
import 'package:itogram_edupulse/features/assignments/presentation/cubit/assignment_cubit.dart';
import 'package:itogram_edupulse/features/assignments/presentation/pages/assignment_control_page.dart';
import 'package:itogram_edupulse/features/assignments/presentation/pages/submission_grading_detail_page.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/page_harness.dart';

final DateTime _due = DateTime(2026, 11, 12, 23, 59);

AssignmentEntity _assignment({DateTime? due}) => AssignmentEntity(
      assignmentId: 'hw-1',
      courseId: 'c-mob',
      courseName: 'Mobil Programlama',
      title: 'Flutter Todo Uygulaması',
      description: 'Cubit ile todo listesi',
      rubricCriteria: 'Mimari %40, UI %30, Test %30',
      dueDate: due ?? _due,
    );

void main() {
  group('Kural 2 — UploadAssignmentSubmissionUseCase.buildSubmission', () {
    test('son teslimden önce: submitted, ceza yok', () {
      final s = UploadAssignmentSubmissionUseCase.buildSubmission(
        assignment: _assignment(),
        studentUid: 'u',
        studentName: 'n',
        localFilePath: '/tmp/a.pdf',
        fileName: 'a.pdf',
        submittedAt: _due.subtract(const Duration(minutes: 1)),
      );
      expect(s.status, SubmissionStatus.submitted);
      expect(s.isLatePenaltyApplied, isFalse);
    });

    test('son teslimden sonra: yükleme ENGELLENMEZ, late + -10 ceza bayrağı', () {
      final s = UploadAssignmentSubmissionUseCase.buildSubmission(
        assignment: _assignment(),
        studentUid: 'u',
        studentName: 'n',
        localFilePath: '/tmp/a.pdf',
        fileName: 'a.pdf',
        submittedAt: _due.add(const Duration(seconds: 1)),
      );
      expect(s.status, SubmissionStatus.late);
      expect(s.isLatePenaltyApplied, isTrue);
    });

    test('puan önizlemesi: geç teslimde 10 puan düşer, en az 0', () {
      expect(GradeAndFeedbackUseCase.previewFinalScore(85, isLate: true), 75);
      expect(GradeAndFeedbackUseCase.previewFinalScore(85, isLate: false), 85);
      expect(GradeAndFeedbackUseCase.previewFinalScore(5, isLate: true), 0);
    });
  });

  group('AssignmentCubit', () {
    late TestBackend backend;
    late AssignmentCubit cubit;

    setUp(() async {
      backend = TestBackend();
      await backend.register();
      cubit = GetIt.instance<AssignmentCubit>();
    });
    tearDown(() => cubit.close());

    Future<void> flush() => Future<void>.delayed(const Duration(milliseconds: 10));

    test('dersler yüklenir, ilk dersin ödevleri son teslime göre sıralı gelir', () async {
      backend.assignments.assignments.items.addAll([
        _assignment(due: DateTime(2026, 12, 1)),
        AssignmentEntity(
          assignmentId: 'hw-0',
          courseId: 'c-mob',
          courseName: 'Mobil Programlama',
          title: 'Erken Ödev',
          description: '',
          rubricCriteria: '',
          dueDate: DateTime(2026, 11, 20),
        ),
      ]);
      cubit.start();
      await flush();
      expect(cubit.state.selectedCourseId, 'c-mob');
      expect(cubit.state.assignments.map((a) => a.assignmentId), ['hw-0', 'hw-1']);
    });

    test('dosya yüklemesi ilerleme yüzdesini yayar ve teslim kaydı oluşur', () async {
      final progress = <double>[];
      final sub = cubit.stream.listen((s) {
        final p = s.upload?.progress;
        if (p != null && (progress.isEmpty || progress.last != p)) progress.add(p);
      });
      await cubit.uploadSubmission(
        assignment: _assignment(due: DateTime.now().add(const Duration(days: 1))),
        studentUid: 'uid-student',
        studentName: 'Merve',
        localFilePath: '/tmp/odev.pdf',
        fileName: 'odev.pdf',
      );
      await sub.cancel();

      expect(progress, [0, 0.25, 0.75, 1.0]);
      expect(cubit.state.upload?.isCompleted, isTrue);
      expect(cubit.state.upload?.isLate, isFalse);
      expect(backend.assignments.submissions.items.single.status, SubmissionStatus.submitted);
    });

    test('Kural 2: geç yükleme kabul edilir ve -10 ceza mesajı verilir', () async {
      await cubit.uploadSubmission(
        assignment: _assignment(due: DateTime.now().subtract(const Duration(hours: 1))),
        studentUid: 'uid-student',
        studentName: 'Merve',
        localFilePath: '/tmp/odev.pdf',
        fileName: 'odev.pdf',
      );
      final saved = backend.assignments.submissions.items.single;
      expect(saved.status, SubmissionStatus.late);
      expect(saved.isLatePenaltyApplied, isTrue);
      expect(cubit.state.actionMessage, contains('-10 Ceza Puanı'));
    });

    test('yükleme hatasında ilerleme çubuğu hata mesajı gösterir', () async {
      backend.assignments.error = Exception('storage/unauthorized');
      await cubit.uploadSubmission(
        assignment: _assignment(),
        studentUid: 'u',
        studentName: 'n',
        localFilePath: '/tmp/a.pdf',
        fileName: 'a.pdf',
      );
      expect(cubit.state.upload?.errorMessage, contains('storage/unauthorized'));
      expect(cubit.state.upload?.isUploading, isFalse);
    });

    test('eğitmen puanı 0-100 dışında kaydedilemez', () async {
      expect(await cubit.gradeSubmission(assignmentId: 'hw-1', submissionId: 's', rawScore: 120), isFalse);
      expect(backend.assignments.grades, isEmpty);
      expect(await cubit.gradeSubmission(assignmentId: 'hw-1', submissionId: 's', rawScore: 90, writtenFeedback: 'İyi'),
          isTrue);
      expect(backend.assignments.grades.single['rawScore'], 90);
    });
  });

  group('AssignmentControlPage / SubmissionGradingDetailPage', () {
    late TestBackend backend;
    setUp(() async {
      backend = TestBackend();
      await backend.register();
      backend.assignments.assignments.items.add(_assignment(due: DateTime.now().add(const Duration(days: 2))));
    });

    testWidgets('öğrenci ödev kartını görür; "Yeni Ödev & Rubrik Aç" butonu yoktur (Kural 5)', (tester) async {
      await pumpPage(tester, const AssignmentControlPage(), backend: backend);
      expect(find.text('Flutter Todo Uygulaması'), findsOneWidget);
      expect(find.byKey(const Key('assignment_create')), findsNothing);
    });

    testWidgets('eğitmen "Yeni Ödev & Rubrik Aç" butonunu görür', (tester) async {
      await pumpPage(tester, const AssignmentControlPage(), backend: backend, role: UserRole.instructor);
      expect(find.byKey(const Key('assignment_create')), findsOneWidget);
    });

    testWidgets('öğrenci notlandırma sayfasını açamaz (çift kalkan)', (tester) async {
      await pumpPage(
        tester,
        const SubmissionGradingDetailPage(submissionId: 'uid-student', assignmentId: 'hw-1'),
        backend: backend,
      );
      expect(find.text('Yetkisiz erişim'), findsOneWidget);
      expect(find.byKey(const Key('grading_save')), findsNothing);
    });

    testWidgets('eğitmen geç teslime puan girince -10 cezalı önizleme görür ve kaydeder', (tester) async {
      backend.assignments.submissions.items.add(submissionOf(assignmentId: 'hw-1', late: true));
      await pumpPage(
        tester,
        const SubmissionGradingDetailPage(submissionId: 'uid-student', assignmentId: 'hw-1'),
        backend: backend,
        role: UserRole.instructor,
      );
      expect(find.textContaining('GECİKMİŞ TESLİM'), findsWidgets);

      await tester.enterText(find.byKey(const Key('grading_score')), '85');
      await tester.pump();
      expect(find.text('Öğrencinin göreceği puan: 75 (-10 gecikme cezası)'), findsOneWidget);

      await tester.scrollUntilVisible(find.byKey(const Key('grading_save')), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(const Key('grading_save')));
      await settle(tester);
      expect(backend.assignments.grades.single['rawScore'], 85);
    });

    testWidgets('100\'den büyük puan formda reddedilir', (tester) async {
      backend.assignments.submissions.items.add(submissionOf(assignmentId: 'hw-1'));
      await pumpPage(
        tester,
        const SubmissionGradingDetailPage(submissionId: 'uid-student', assignmentId: 'hw-1'),
        backend: backend,
        role: UserRole.instructor,
      );
      await tester.enterText(find.byKey(const Key('grading_score')), '100');
      final text = tester.widget<EditableText>(
        find.descendant(of: find.byKey(const Key('grading_score')), matching: find.byType(EditableText)),
      );
      expect(double.parse(text.controller.text), lessThanOrEqualTo(100));
    });
  });
}
