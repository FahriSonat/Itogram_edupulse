import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/constants/firestore_paths.dart';
import 'package:itogram_edupulse/core/enums/attendance_status.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/error/failures.dart';
import 'package:itogram_edupulse/core/services/fcm_notification_service.dart';
import 'package:itogram_edupulse/core/services/local_storage_service.dart';
import 'package:itogram_edupulse/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:itogram_edupulse/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:itogram_edupulse/features/attendance/domain/entities/student_absence_record_entity.dart';
import 'package:itogram_edupulse/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/generate_60s_qr_pin_usecase.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/manage_attendance_record_usecase.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/submit_live_attendance_usecase.dart';
import 'package:itogram_edupulse/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:itogram_edupulse/features/auth/domain/entities/user_entity.dart';
import 'package:itogram_edupulse/features/schedule/domain/entities/course_schedule_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStorageService storage;
  late AttendanceRepository repository;
  late DateTime clockNow;
  late Generate60sQrPinUseCase pinGenerator;
  late SubmitLiveAttendanceUseCase submit;
  late ManageAttendanceRecordUseCase manage;
  late List<UserEntity> students;

  const instructor = UserEntity(
    uid: 'i_mustafa',
    fullName: 'Mustafa Hoca',
    email: 'mustafa.hoca@edupulse.edu.tr',
    schoolNo: '1001',
    role: UserRole.instructor,
  );
  const course = CourseScheduleEntity(
    id: 'c_mob101',
    courseCode: 'MOB101',
    courseName: 'Flutter ile Mobil Geliştirme',
    instructorUid: 'i_mustafa',
    instructorName: 'Mustafa Hoca',
    roomLocation: 'A204',
    dayOfWeek: 1,
    startTime: '10:30',
    endTime: '12:00',
    credit: 6,
  );

  UserEntity student(String uid) => students.firstWhere((s) => s.uid == uid);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorageService(await SharedPreferences.getInstance());
    await storage.init();
    repository = AttendanceRepositoryImpl(
      remote: LocalAttendanceRemoteDataSource(storage),
      notifications: NotificationService(storage),
    );
    clockNow = DateTime(2026, 11, 9, 10, 35);
    pinGenerator = Generate60sQrPinUseCase(repository, clock: () => clockNow);
    submit = SubmitLiveAttendanceUseCase(repository, clock: () => clockNow);
    manage = ManageAttendanceRecordUseCase(repository, pinGenerator: pinGenerator);
    students = await LocalAuthRemoteDataSource(storage).getUsersByRole(UserRole.student);
  });

  group('Kural 1 — 60 Sn Yoklama Kalkanı', () {
    test('4 haneli PIN üretir ve 60 sn sonra geçersiz olur', () {
      final code = pinGenerator.generate(sessionId: 's1');
      expect(code.pin, matches(RegExp(r'^\d{4}$')));
      expect(code.expiresAt, clockNow.add(const Duration(seconds: 60)));
      expect(code.qrToken, contains(code.pin));
    });

    test('ders saati 45 dk = 1 saat olarak hesaplanır (90 dk → 2 saat)', () {
      expect(ManageAttendanceRecordUseCase.sessionHoursFor(course), 2);
    });

    test('60 sn içinde girilen doğru PIN ile öğrenci "Gelen" olur', () async {
      final session = await manage.start(actor: instructor, course: course, students: students);
      clockNow = clockNow.add(const Duration(seconds: 59));

      final updated = await submit(actor: student('u_ayberk'), code: session.pinCode);

      expect(updated.markFor('u_ayberk')!.status, AttendanceStatus.present);
      expect(repository.getSession(session.id)!.countOf(AttendanceStatus.present), 1);
    });

    test('60. saniyede PIN reddedilir (süre doldu)', () async {
      final session = await manage.start(actor: instructor, course: course, students: students);
      clockNow = clockNow.add(const Duration(seconds: 60));

      expect(
        () => submit(actor: student('u_ayberk'), code: session.pinCode),
        throwsA(isA<ValidationFailure>().having((f) => f.message, 'message', AppStrings.qrExpiredError)),
      );
    });

    test('kod yenilenince eski PIN geçersiz, yeni PIN geçerli olur', () async {
      final session = await manage.start(actor: instructor, course: course, students: students);
      clockNow = clockNow.add(const Duration(seconds: 61));
      final refreshed = await pinGenerator.refresh(actor: instructor, sessionId: session.id);

      expect(refreshed.pinCode, isNot(session.pinCode));
      expect(() => submit(actor: student('u_meltem'), code: session.pinCode), throwsA(isA<ValidationFailure>()));
      final ok = await submit(actor: student('u_meltem'), code: refreshed.pinCode);
      expect(ok.markFor('u_meltem')!.status, AttendanceStatus.present);
    });

    test('hatalı PIN ve tekrar katılım reddedilir', () async {
      final session = await manage.start(actor: instructor, course: course, students: students);
      final wrong = session.pinCode == '0000' ? '1111' : '0000';

      expect(
        () => submit(actor: student('u_ayberk'), code: wrong),
        throwsA(
          isA<ValidationFailure>().having((f) => f.message, 'message', SubmitLiveAttendanceUseCase.wrongCodeError),
        ),
      );
      await submit(actor: student('u_ayberk'), code: session.pinCode);
      expect(
        () => submit(actor: student('u_ayberk'), code: session.pinCode),
        throwsA(
          isA<ValidationFailure>().having((f) => f.message, 'message', SubmitLiveAttendanceUseCase.alreadyPresentError),
        ),
      );
    });

    test('Kural 5: eğitmen PIN giremez, öğrenci yoklama başlatamaz', () async {
      final session = await manage.start(actor: instructor, course: course, students: students);
      expect(() => submit(actor: instructor, code: session.pinCode), throwsA(isA<UnauthorizedFailure>()));
      expect(
        () => manage.start(actor: student('u_ayberk'), course: course, students: students),
        throwsA(isA<UnauthorizedFailure>()),
      );
    });
  });

  group('Kural 3 — Oturum kapanışında devamsızlık işlenir', () {
    test('gelmeyenlere ders saati eklenir, %20 sınırını yeni aşan uyarılır', () async {
      final session = await manage.start(actor: instructor, course: course, students: students);
      await submit(actor: student('u_ayberk'), code: session.pinCode);
      await manage.setStatus(
        actor: instructor,
        sessionId: session.id,
        studentUid: 'u_elif',
        status: AttendanceStatus.excused,
      );

      final summary = await manage.end(actor: instructor, sessionId: session.id);

      expect(summary.present, 1);
      expect(summary.excused, 1);
      expect(summary.absent, students.length - 2);

      int hours(String uid) => repository
          .getAbsenceRecords()
          .firstWhere((r) => r.id == StudentAbsenceRecordEntity.buildId(uid, 'c_mob101'))
          .absentHours;

      expect(hours('u_ayberk'), 4, reason: 'Gelen öğrencinin devamsızlığı değişmez');
      expect(hours('u_elif'), 2, reason: 'İzinli öğrenciye devamsızlık yazılmaz');
      expect(hours('u_can'), 8, reason: '6 + 2 saat');

      // Can Demir 6/40 → 8/40 (%20) ile sınırı yeni aştı; Ahmet zaten kritikti.
      expect(summary.newlyCritical, 1);
      final notifications = storage.getAll(FirestorePaths.notifications).map(AppNotification.fromJson);
      expect(notifications.where((n) => n.targetUid == 'u_can' && n.kind == NotificationKind.absence), hasLength(1));
      expect(repository.getSession(session.id)!.isActive, isFalse);
    });
  });
}
