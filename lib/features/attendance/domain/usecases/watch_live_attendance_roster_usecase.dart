import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/attendance_session_entity.dart';
import '../repositories/attendance_repository.dart';

/// Sınıftaki öğrencilerin canlı yoklama durumunu (Gelen/Gelmeyen/İzinli) akış olarak sunar.
class WatchLiveAttendanceRosterUseCase {
  const WatchLiveAttendanceRosterUseCase(this._repository);

  final AttendanceRepository _repository;

  Stream<Either<Failure, AttendanceSessionEntity?>> call(String sessionId) =>
      guardStream(_repository.watchLiveAttendanceRoster(sessionId));
}
