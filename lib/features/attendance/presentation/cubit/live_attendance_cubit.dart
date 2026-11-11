import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/attendance_status.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../../domain/usecases/generate_60s_qr_pin_usecase.dart';
import '../../domain/usecases/manage_attendance_record_usecase.dart';
import '../../domain/usecases/submit_live_attendance_usecase.dart';
import '../../domain/usecases/watch_live_attendance_roster_usecase.dart';
import 'live_attendance_state.dart';

class LiveAttendanceCubit extends Cubit<LiveAttendanceState> {
  LiveAttendanceCubit({
    required this._watchRoster,
    required this._pinGenerator,
    required this._submitAttendance,
    required this._manageRecords,
    required this._authRepository,
  }) : super(const LiveAttendanceState()) {
    start();
  }

  final WatchLiveAttendanceRosterUseCase _watchRoster;
  final Generate60sQrPinUseCase _pinGenerator;
  final SubmitLiveAttendanceUseCase _submitAttendance;
  final ManageAttendanceRecordUseCase _manageRecords;
  final AuthRepository _authRepository;

  StreamSubscription<List<AttendanceSessionEntity>>? _sub;
  bool _refreshing = false;

  void start() {
    emit(state.copyWith(status: ViewStatus.loading));
    _sub?.cancel();
    _sub = _watchRoster().listen(
      (sessions) => emit(state.copyWith(status: ViewStatus.loaded, sessions: sessions)),
      onError: (Object e) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: Failure.from(e).message)),
    );
  }

  Future<void> startSession({required UserEntity actor, required CourseScheduleEntity course}) async {
    emit(state.copyWith(isBusy: true));
    try {
      final students = await _authRepository.getStudents();
      await _manageRecords.start(actor: actor, course: course, students: students);
    } finally {
      emit(state.copyWith(isBusy: false));
    }
  }

  /// 60 saniye dolduğunda eğitmen panosu tarafından çağrılır.
  Future<void> refreshPin({required UserEntity actor, required String sessionId}) async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      await _pinGenerator.refresh(actor: actor, sessionId: sessionId);
    } catch (e) {
      emit(state.copyWith(errorMessage: Failure.from(e).message));
    } finally {
      _refreshing = false;
    }
  }

  Future<void> setStatus({
    required UserEntity actor,
    required String sessionId,
    required String studentUid,
    required AttendanceStatus status,
  }) => _manageRecords.setStatus(actor: actor, sessionId: sessionId, studentUid: studentUid, status: status);

  Future<AttendanceSummary> endSession({required UserEntity actor, required String sessionId}) async {
    emit(state.copyWith(isBusy: true));
    try {
      return await _manageRecords.end(actor: actor, sessionId: sessionId);
    } finally {
      emit(state.copyWith(isBusy: false));
    }
  }

  /// Öğrenci PIN / QR girişi. Başarılıysa katıldığı oturumu döndürür, değilse [Failure] fırlatır.
  Future<AttendanceSessionEntity> submitCode({required UserEntity actor, required String code}) =>
      _submitAttendance(actor: actor, code: code);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
