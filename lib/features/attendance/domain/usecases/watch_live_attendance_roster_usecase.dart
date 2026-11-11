import '../entities/attendance_session_entity.dart';
import '../repositories/attendance_repository.dart';

/// Yoklama oturumlarını canlı dinler; öğrenci PIN girdiğinde eğitmenin
/// "Gelen / Gelmeyen / İzinli" listesi anında güncellenir.
class WatchLiveAttendanceRosterUseCase {
  const WatchLiveAttendanceRosterUseCase(this._repository);

  final AttendanceRepository _repository;

  Stream<List<AttendanceSessionEntity>> call() => _repository.watchSessions();
}
