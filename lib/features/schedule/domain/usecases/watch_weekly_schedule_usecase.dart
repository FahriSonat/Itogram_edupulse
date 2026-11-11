import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/course_schedule_entity.dart';
import '../repositories/schedule_repository.dart';

/// Haftalık ders programını canlı izler (eğitmen değişikliği anında yansır).
class WatchWeeklyScheduleUseCase {
  const WatchWeeklyScheduleUseCase(this._repository);

  final ScheduleRepository _repository;

  Stream<Either<Failure, List<CourseScheduleEntity>>> call() => guardStream(_repository.watchWeeklySchedule());
}
