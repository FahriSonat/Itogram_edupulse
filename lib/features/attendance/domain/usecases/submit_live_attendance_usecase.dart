import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../repositories/attendance_repository.dart';

/// Öğrencinin PIN / QR ile yoklama vermesi. Süresi dolmuş kodda
/// [ExpiredCodeFailure] döner (Kural 1).
class SubmitLiveAttendanceUseCase {
  const SubmitLiveAttendanceUseCase(this._repository);

  final AttendanceRepository _repository;

  static final RegExp _pin = RegExp(r'^\d{4}$');

  /// [sessionId] boş bırakılabilir: datasource oturumu PIN veya QR içeriğinden bulur.
  Future<Either<Failure, Unit>> call({
    required String studentUid,
    required String code,
    String sessionId = '',
  }) async {
    final trimmed = code.trim();
    final isQr = trimmed.startsWith('EDUPULSE|');
    if (!isQr && !_pin.hasMatch(trimmed)) {
      return const Left(ServerFailure('PIN 4 haneli olmalıdır.'));
    }
    return guardFailure(() async {
      await _repository.submitLiveAttendance(sessionId: sessionId, studentUid: studentUid, code: trimmed);
      return unit;
    });
  }
}
