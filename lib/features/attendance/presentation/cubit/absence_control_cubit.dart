import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/view_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/role_guard.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/student_absence_record_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'absence_control_state.dart';

class AbsenceControlCubit extends Cubit<AbsenceControlState> {
  AbsenceControlCubit({required this._repository}) : super(const AbsenceControlState()) {
    start();
  }

  final AttendanceRepository _repository;
  StreamSubscription<List<StudentAbsenceRecordEntity>>? _sub;

  void start() {
    emit(state.copyWith(status: ViewStatus.loading));
    _sub?.cancel();
    _sub = _repository.watchAbsenceRecords().listen(
      (records) => emit(state.copyWith(status: ViewStatus.loaded, records: records)),
      onError: (Object e) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: Failure.from(e).message)),
    );
  }

  /// Kural 3 + 5: Eğitmen kritik listedeki öğrenciye anlık uyarı gönderir.
  Future<void> sendPushWarning({required UserEntity actor, required StudentAbsenceRecordEntity record}) async {
    RoleGuard.requireInstructor(actor.role);
    await _repository.sendAbsenceWarning(record: record, senderName: actor.fullName);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
