// Geliştirici 5 & 6 — 2.2 Canlı Yoklama: LiveAttendanceCubit + LiveAttendancePage.
// Kural 1: 60 saniyede bir yeni QR/PIN; süresi dolan kodla yoklama verilemez.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/attendance_status.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/error/exceptions.dart';
import 'package:itogram_edupulse/features/attendance/domain/entities/attendance_session_entity.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/generate_60s_qr_pin_usecase.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/manage_attendance_record_usecase.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/submit_live_attendance_usecase.dart';
import 'package:itogram_edupulse/features/attendance/domain/usecases/watch_live_attendance_roster_usecase.dart';
import 'package:itogram_edupulse/features/attendance/presentation/cubit/live_attendance_cubit.dart';
import 'package:itogram_edupulse/features/attendance/presentation/cubit/live_attendance_state.dart';
import 'package:itogram_edupulse/features/attendance/presentation/pages/live_attendance_page.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/dynamic_qr_pin_board.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/page_harness.dart';

void main() {
  late FakeAttendanceRepository repo;
  late LiveAttendanceCubit cubit;

  LiveAttendanceCubit build() => LiveAttendanceCubit(
        generate60sQrPinUseCase: Generate60sQrPinUseCase(repo),
        submitLiveAttendanceUseCase: SubmitLiveAttendanceUseCase(repo),
        watchLiveAttendanceRosterUseCase: WatchLiveAttendanceRosterUseCase(repo),
        manageAttendanceRecordUseCase: ManageAttendanceRecordUseCase(repo),
      );

  setUp(() {
    repo = FakeAttendanceRepository();
    cubit = build();
  });

  group('Eğitmen — 60 sn QR/PIN döngüsü', () {
    testWidgets('yoklama başlayınca kod üretilir ve her 60 saniyede yenilenir', (tester) async {
      cubit.startSession('c-mob');
      await tester.pump();
      expect(cubit.state.status, LiveAttendanceStatus.active);
      expect(repo.generated.length, 1);
      expect(cubit.state.session?.pinCode, '1001');
      expect(cubit.state.remainingSeconds, inInclusiveRange(59, 60));

      await tester.pump(const Duration(seconds: 60));
      await tester.pump();
      expect(repo.generated.length, 2, reason: 'Timer.periodic(60 sn) yeni kod üretmeli');
      expect(cubit.state.session?.pinCode, '1002');

      await tester.pump(const Duration(seconds: 60));
      await tester.pump();
      expect(repo.generated.length, 3);

      cubit.stopSession();
      await tester.pump(const Duration(seconds: 120));
      expect(repo.generated.length, 3, reason: 'yoklama bitince kod üretimi durmalı');
      await cubit.close();
    });

    testWidgets('kod yenilense de "Geldi" olan öğrenci listeden düşmez', (tester) async {
      repo.initialStatuses = const {'uid-1': AttendanceStatus.absent, 'uid-2': AttendanceStatus.absent};
      cubit.startSession('c-mob');
      await tester.pump();
      final first = repo.generated.single;

      // uid-1 ilk kodla katıldı (Firestore roster güncellemesi).
      repo.rosters['c-mob/${first.sessionId}']!.add(AttendanceSessionEntity(
        sessionId: first.sessionId,
        courseId: 'c-mob',
        qrCodeToken: first.qrCodeToken,
        pinCode: first.pinCode,
        createdAt: first.createdAt,
        expiresAt: first.expiresAt,
        isActive: true,
        studentStatusMap: const {'uid-1': AttendanceStatus.present, 'uid-2': AttendanceStatus.absent},
      ));
      await tester.pump();
      expect(cubit.state.statuses['uid-1'], AttendanceStatus.present);

      // 60 sn sonra yeni oturum (başlangıçta herkes "absent").
      await tester.pump(const Duration(seconds: 60));
      await tester.pump();
      expect(repo.generated.length, 2);
      expect(cubit.state.statuses['uid-1'], AttendanceStatus.present);
      expect(cubit.state.countOf(AttendanceStatus.present), 1);
      expect(cubit.state.countOf(AttendanceStatus.absent), 1);
      await cubit.close();
    });

    testWidgets('eğitmen öğrenciyi elle "İzinli" yapar → depoya yazılır', (tester) async {
      cubit.startSession('c-mob');
      await tester.pump();
      await cubit.changeStatus('uid-1', AttendanceStatus.excused);
      expect(cubit.state.statuses['uid-1'], AttendanceStatus.excused);
      expect(repo.updates.single, ('c-mob', 'uid-1', AttendanceStatus.excused));
      await cubit.close();
    });

    testWidgets('close() tüm zamanlayıcıları durdurur (dispose güvenli)', (tester) async {
      cubit.startSession('c-mob');
      await tester.pump();
      await cubit.close();
      await tester.pump(const Duration(minutes: 5));
      expect(repo.generated.length, 1);
    });
  });

  group('Öğrenci — PIN ile yoklama (Kural 1)', () {
    test('geçerli PIN → submitted', () async {
      await cubit.submitCode(studentUid: 'uid-1', code: '4821');
      expect(cubit.state.status, LiveAttendanceStatus.submitted);
      expect(repo.submittedCodes, ['4821']);
    });

    test('süresi dolmuş kod → failure + isCodeExpired', () async {
      repo.submitError = const ExpiredQrPinException();
      await cubit.submitCode(studentUid: 'uid-1', code: '4821');
      expect(cubit.state.status, LiveAttendanceStatus.failure);
      expect(cubit.state.isCodeExpired, isTrue);
    });

    test('4 haneli olmayan PIN depoya gönderilmez', () async {
      await cubit.submitCode(studentUid: 'uid-1', code: '12');
      expect(cubit.state.status, LiveAttendanceStatus.failure);
      expect(repo.submittedCodes, isEmpty);
    });

    test('QR içeriği (EDUPULSE|...) PIN kuralına takılmaz', () async {
      await cubit.submitCode(studentUid: 'uid-1', code: 'EDUPULSE|c-mob|sess-1|4821');
      expect(cubit.state.status, LiveAttendanceStatus.submitted);
    });
  });

  group('LiveAttendancePage', () {
    late TestBackend backend;
    setUp(() async {
      backend = TestBackend();
      await backend.register();
    });

    testWidgets('öğrenci PIN giriş alanını görür, "Yoklamayı Başlat" butonunu görmez (Kural 5)', (tester) async {
      await pumpPage(tester, const LiveAttendancePage(), backend: backend);
      expect(find.text('Derse Katıl'), findsOneWidget);
      expect(find.byKey(const Key('attendance_start')), findsNothing);
    });

    testWidgets('eğitmen ders seçip yoklamayı başlatır; PIN panoda görünür', (tester) async {
      await pumpPage(tester, const LiveAttendancePage(), backend: backend, role: UserRole.instructor);
      expect(find.byKey(const Key('attendance_start')), findsOneWidget);

      await tester.tap(find.byKey(const Key('attendance_start')));
      await settle(tester);
      expect(backend.attendance.generated, isNotEmpty);
      expect(find.byType(DynamicQrPinBoard), findsOneWidget);
      expect(find.text('4 Haneli Hızlı Katılım Kodu'), findsOneWidget);
      expect(find.text('Gelmeyen (1)'), findsOneWidget, reason: 'canlı katılımcı listesi');

      await tester.scrollUntilVisible(find.byKey(const Key('attendance_stop')), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(const Key('attendance_stop')));
      await settle(tester);
      expect(find.byKey(const Key('attendance_start')), findsOneWidget);
    });
  });
}
