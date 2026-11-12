import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/attendance_session_entity.dart';
import '../repositories/attendance_repository.dart';

/// Eğitmen için 60 saniye geçerli yeni QR + 4 haneli PIN üretir (Kural 1).
class Generate60sQrPinUseCase {
  const Generate60sQrPinUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Either<Failure, AttendanceSessionEntity>> call(String courseId) =>
      guardFailure(() => _repository.generateAttendanceSession(courseId));
}
