import '../entities/course_schedule_entity.dart';
import '../repositories/schedule_repository.dart';

/// Haftalık ders programını reaktif olarak dinler (gün ve saate göre sıralı).
class WatchWeeklyScheduleUseCase {
  const WatchWeeklyScheduleUseCase(this._repository);

  final ScheduleRepository _repository;

  Stream<List<CourseScheduleEntity>> call() => _repository.watchWeeklySchedule();
}
