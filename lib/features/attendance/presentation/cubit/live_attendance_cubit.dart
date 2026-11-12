import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/attendance_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../../domain/usecases/generate_60s_qr_pin_usecase.dart';
import '../../domain/usecases/manage_attendance_record_usecase.dart';
import '../../domain/usecases/submit_live_attendance_usecase.dart';
import '../../domain/usecases/watch_live_attendance_roster_usecase.dart';
import 'live_attendance_state.dart';

/// Eğitmen yoklamayı başlattığında `Timer.periodic(60 sn)` ile her dakika yeni
/// QR + 4 haneli PIN üretir; saniye saniye geri sayımı ve canlı katılımcı
/// listesini yönetir. Öğrenci tarafında PIN/QR gönderimini yürütür.
class LiveAttendanceCubit extends Cubit<LiveAttendanceState> {
  LiveAttendanceCubit({
    required this.generate60sQrPinUseCase,
    required this.submitLiveAttendanceUseCase,
    required this.watchLiveAttendanceRosterUseCase,
    required this.manageAttendanceRecordUseCase,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(const LiveAttendanceState());

  final Generate60sQrPinUseCase generate60sQrPinUseCase;
  final SubmitLiveAttendanceUseCase submitLiveAttendanceUseCase;
  final WatchLiveAttendanceRosterUseCase watchLiveAttendanceRosterUseCase;
  final ManageAttendanceRecordUseCase manageAttendanceRecordUseCase;
  final DateTime Function() _clock;

  Timer? _rotationTimer;
  Timer? _countdownTimer;
  StreamSubscription<dynamic>? _rosterSub;
  StreamSubscription<dynamic>? _classSub;

  // ---------------------------------------------------------------- Eğitmen

  Future<void> startSession(String courseId) async {
    _stopTimers();
    emit(LiveAttendanceState(status: LiveAttendanceStatus.starting, courseId: courseId));

    _classSub?.cancel();
    _classSub = manageAttendanceRecordUseCase.watchClass(courseId).listen((result) {
      result.fold((_) {}, (records) {
        final students = <String, RosterStudent>{
          for (final r in records) r.studentUid: (name: r.studentName, studentNo: r.studentNo),
        };
        final statuses = Map<String, AttendanceStatus>.of(state.statuses);
        for (final uid in students.keys) {
          statuses.putIfAbsent(uid, () => AttendanceStatus.absent);
        }
        emit(state.copyWith(students: students, statuses: statuses));
      });
    });

    if (!await _rotateCode()) return;

    _rotationTimer = Timer.periodic(
      const Duration(seconds: DateTimeHelper.qrPinValiditySeconds),
      (_) => _rotateCode(),
    );
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Yeni kod üretir ve yeni oturumun katılımcılarını dinlemeye başlar.
  Future<bool> _rotateCode() async {
    final courseId = state.courseId;
    if (courseId == null) return false;
    final result = await generate60sQrPinUseCase(courseId);
    if (isClosed) return false;
    return result.fold(
      (failure) {
        _stopTimers();
        emit(state.copyWith(status: LiveAttendanceStatus.failure, message: failure.message));
        return false;
      },
      (session) {
        emit(state.copyWith(
          status: LiveAttendanceStatus.active,
          session: session,
          remainingSeconds: _remaining(session),
          statuses: _merge(state.statuses, session.studentStatusMap),
        ));
        _listenRoster(session);
        return true;
      },
    );
  }

  void _listenRoster(AttendanceSessionEntity session) {
    _rosterSub?.cancel();
    _rosterSub = watchLiveAttendanceRosterUseCase('${session.courseId}/${session.sessionId}').listen((result) {
      result.fold((_) {}, (live) {
        if (live == null || isClosed) return;
        emit(state.copyWith(statuses: _merge(state.statuses, live.studentStatusMap)));
      });
    });
  }

  /// Bir öğrenci herhangi bir 60 sn'lik kodla "Geldi" olduysa, sonraki
  /// oturumların "Gelmedi" başlangıç değeri bunu ezmez.
  static Map<String, AttendanceStatus> _merge(
    Map<String, AttendanceStatus> accumulated,
    Map<String, AttendanceStatus> incoming,
  ) {
    final merged = Map<String, AttendanceStatus>.of(accumulated);
    incoming.forEach((uid, status) {
      if (status != AttendanceStatus.absent || !merged.containsKey(uid)) merged[uid] = status;
    });
    return merged;
  }

  int _remaining(AttendanceSessionEntity s) => DateTimeHelper.qrPinRemainingSeconds(s.expiresAt, now: _clock());

  void _tick() {
    final session = state.session;
    if (session == null || isClosed) return;
    emit(state.copyWith(remainingSeconds: _remaining(session)));
  }

  /// Eğitmenin listeden öğrenci durumunu elle değiştirmesi (Gelen/İzinli...).
  Future<void> changeStatus(String studentUid, AttendanceStatus status) async {
    final courseId = state.courseId;
    if (courseId == null) return;
    final previous = state.statuses;
    emit(state.copyWith(statuses: <String, AttendanceStatus>{...previous, studentUid: status}));
    final result = await manageAttendanceRecordUseCase(courseId: courseId, studentUid: studentUid, status: status);
    result.fold(
      (failure) => emit(state.copyWith(statuses: previous, message: failure.message)),
      (_) {},
    );
  }

  void stopSession() {
    _stopTimers();
    _rosterSub?.cancel();
    _classSub?.cancel();
    emit(const LiveAttendanceState());
  }

  void _stopTimers() {
    _rotationTimer?.cancel();
    _countdownTimer?.cancel();
    _rotationTimer = null;
    _countdownTimer = null;
  }

  // ---------------------------------------------------------------- Öğrenci

  Future<void> submitCode({required String studentUid, required String code}) async {
    emit(state.copyWith(status: LiveAttendanceStatus.submitting));
    final result = await submitLiveAttendanceUseCase(studentUid: studentUid, code: code);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        status: LiveAttendanceStatus.failure,
        message: failure.message,
        isCodeExpired: failure is ExpiredCodeFailure,
      )),
      (_) => emit(state.copyWith(status: LiveAttendanceStatus.submitted, message: 'Yoklamanız alındı.')),
    );
  }

  /// Öğrenci hatadan sonra yeniden kod girmek istediğinde.
  void resetStudent() => emit(const LiveAttendanceState());

  @override
  Future<void> close() {
    _stopTimers();
    _rosterSub?.cancel();
    _classSub?.cancel();
    return super.close();
  }
}
