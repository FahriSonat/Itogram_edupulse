import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/course_schedule_entity.dart';
import '../repositories/schedule_repository.dart';

/// Mevcut dersin amfi, hoca adı veya saatini günceller.
class UpdateCourseDetailsUseCase {
  const UpdateCourseDetailsUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Either<Failure, Unit>> call(CourseScheduleEntity course) async {
    if (course.courseId.isEmpty) {
      return const Left(ServerFailure('Güncellenecek ders bulunamadı.'));
    }
    return guardFailure(() async {
      await _repository.updateCourse(course);
      return unit;
    });
  }
}
