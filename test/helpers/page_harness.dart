// Sayfa (Page) widget testleri için ortak düzenek:
// - GetIt'e sahte repository'lerle çalışan gerçek UseCase + Cubit'ler kaydedilir,
// - AuthCubit istenen rolle "giriş yapmış" hale getirilir,
// - sayfa gerçek EduPulse temasıyla telefon boyutunda çizilir.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/theme/app_theme.dart';
import 'package:itogram_edupulse/features/announcements/domain/usecases/create_announcement_usecase.dart';
import 'package:itogram_edupulse/features/announcements/domain/usecases/send_instant_crisis_push_usecase.dart';
import 'package:itogram_edupulse/features/announcements/domain/usecases/watch_announcements_usecase.dart';
import 'package:itogram_edupulse/features/announcements/presentation/cubit/announcement_cubit.dart';
import 'package:itogram_edupulse/features/assignments/domain/usecases/create_assignment_usecase.dart';
import 'package:itogram_edupulse/features/assignments/domain/usecases/grade_and_feedback_usecase.dart';
import 'package:itogram_edupulse/features/assignments/domain/usecases/upload_assignment_submission_usecase.dart';
import 'package:itogram_edupulse/features/assignments/presentation/cubit/assignment_cubit.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/evaluate_absence_risk_usecase.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/generate_60s_qr_pin_usecase.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/manage_attendance_record_usecase.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/submit_live_attendance_usecase.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/watch_live_attendance_roster_usecase.dart';
import 'package:itogram_edupulse/features/attendance/presentation/cubit/absence_control_cubit.dart';
import 'package:itogram_edupulse/features/attendance/presentation/cubit/live_attendance_cubit.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:itogram_edupulse/features/forum/domain/usecases/ask_question_with_photo_usecase.dart';
import 'package:itogram_edupulse/features/forum/domain/usecases/mark_answer_as_resolved_usecase.dart';
import 'package:itogram_edupulse/features/forum/domain/usecases/post_forum_answer_usecase.dart';
import 'package:itogram_edupulse/features/forum/domain/usecases/watch_forum_questions_usecase.dart';
import 'package:itogram_edupulse/features/forum/presentation/cubit/forum_cubit.dart';
import 'package:itogram_edupulse/features/grades/domain/usecases/calculate_gpa_simulation_usecase.dart';
import 'package:itogram_edupulse/features/grades/domain/usecases/manage_student_grade_usecase.dart';
import 'package:itogram_edupulse/features/grades/domain/usecases/watch_student_grades_usecase.dart';
import 'package:itogram_edupulse/features/grades/presentation/cubit/grades_cubit.dart';
import 'package:itogram_edupulse/features/schedule/domain/usecases/add_or_remove_course_usecase.dart';
import 'package:itogram_edupulse/features/schedule/domain/usecases/update_course_details_usecase.dart';
import 'package:itogram_edupulse/features/schedule/domain/usecases/watch_weekly_schedule_usecase.dart';
import 'package:itogram_edupulse/features/schedule/presentation/cubit/schedule_cubit.dart';

import 'fake_auth_repository.dart';
import 'fake_repositories.dart';

/// Tüm sahte repository'ler (testte veriyi buradan hazırla / doğrula).
class TestBackend {
  final FakeScheduleRepository schedule = FakeScheduleRepository();
  final FakeAttendanceRepository attendance = FakeAttendanceRepository();
  final FakeAssignmentRepository assignments = FakeAssignmentRepository();
  final FakeGradesRepository grades = FakeGradesRepository();
  final FakeForumRepository forum = FakeForumRepository();
  final FakeAnnouncementRepository announcements = FakeAnnouncementRepository();
  final FakeAuthRepository auth = FakeAuthRepository();

  /// GetIt'i sıfırlar ve gerçek UseCase / Cubit'leri sahte depolarla kaydeder.
  /// `reset()` asenkron olduğu için mutlaka beklenmelidir; aksi halde kayıtlar
  /// sıfırlama tamamlanınca silinir.
  Future<void> register() async {
    final sl = GetIt.instance;
    await sl.reset();
    final watchSchedule = WatchWeeklyScheduleUseCase(schedule);
    final watchGrades = WatchStudentGradesUseCase(grades);
    final manageAttendance = ManageAttendanceRecordUseCase(attendance);

    sl.registerFactory<ScheduleCubit>(() => ScheduleCubit(
          watchWeeklyScheduleUseCase: watchSchedule,
          addOrRemoveCourseUseCase: AddOrRemoveCourseUseCase(schedule),
          updateCourseDetailsUseCase: UpdateCourseDetailsUseCase(schedule),
        ));
    sl.registerFactory<LiveAttendanceCubit>(() => LiveAttendanceCubit(
          generate60sQrPinUseCase: Generate60sQrPinUseCase(attendance),
          submitLiveAttendanceUseCase: SubmitLiveAttendanceUseCase(attendance),
          watchLiveAttendanceRosterUseCase: WatchLiveAttendanceRosterUseCase(attendance),
          manageAttendanceRecordUseCase: manageAttendance,
        ));
    sl.registerFactory<AbsenceControlCubit>(() => AbsenceControlCubit(
          watchWeeklyScheduleUseCase: watchSchedule,
          evaluateAbsenceRiskUseCase: EvaluateAbsenceRiskUseCase(attendance),
          manageAttendanceRecordUseCase: manageAttendance,
          watchStudentGradesUseCase: watchGrades,
        ));
    sl.registerFactory<AssignmentCubit>(() => AssignmentCubit(
          watchWeeklyScheduleUseCase: watchSchedule,
          createAssignmentUseCase: CreateAssignmentUseCase(assignments),
          uploadAssignmentSubmissionUseCase: UploadAssignmentSubmissionUseCase(assignments),
          gradeAndFeedbackUseCase: GradeAndFeedbackUseCase(assignments),
        ));
    sl.registerFactory<GradesCubit>(() => GradesCubit(
          watchStudentGradesUseCase: watchGrades,
          manageStudentGradeUseCase: ManageStudentGradeUseCase(grades),
          calculateGpaSimulationUseCase: const CalculateGpaSimulationUseCase(),
          watchWeeklyScheduleUseCase: watchSchedule,
        ));
    sl.registerFactory<ForumCubit>(() => ForumCubit(
          watchForumQuestionsUseCase: WatchForumQuestionsUseCase(forum),
          askQuestionWithPhotoUseCase: AskQuestionWithPhotoUseCase(forum),
          postForumAnswerUseCase: PostForumAnswerUseCase(forum),
          markAnswerAsResolvedUseCase: MarkAnswerAsResolvedUseCase(forum),
        ));
    sl.registerFactory<AnnouncementCubit>(() => AnnouncementCubit(
          watchAnnouncementsUseCase: WatchAnnouncementsUseCase(announcements),
          createAnnouncementUseCase: CreateAnnouncementUseCase(announcements),
          sendInstantCrisisPushUseCase: SendInstantCrisisPushUseCase(announcements),
        ));
  }
}

/// Belirtilen rolde giriş yapmış AuthCubit ile [page]'i çizer.
/// `role == null` → oturumsuz (AuthInitial) AuthCubit.
Future<AuthCubit> pumpPage(
  WidgetTester tester,
  Widget page, {
  required TestBackend backend,
  UserRole? role = UserRole.student,
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final auth = buildAuthCubit(backend.auth);
  if (role != null) {
    backend.auth.loginResult = role == UserRole.instructor ? testInstructor : testStudent;
    await auth.login(studentNo: '1', password: 'x');
  }
  addTearDown(auth.close);

  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: auth,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(body: page),
      ),
    ),
  );
  await settle(tester);
  return auth;
}

/// Sonsuz (shimmer, sayaç) animasyonlar yüzünden pumpAndSettle yerine
/// sabit sayıda kare ilerletir; akış olaylarının işlenmesine yeter.
Future<void> settle(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
