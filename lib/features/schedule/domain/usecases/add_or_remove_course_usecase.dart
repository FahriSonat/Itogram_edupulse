import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/course_schedule_entity.dart';
import '../repositories/schedule_repository.dart';

/// Eğitmen için programa ders ekler veya programdan ders çıkarır.
class AddOrRemoveCourseUseCase {
  const AddOrRemoveCourseUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Either<Failure, Unit>> add(CourseScheduleEntity course) async {
    if (course.courseName.trim().isEmpty || course.courseCode.trim().isEmpty) {
      return const Left(ServerFailure('Ders kodu ve adı zorunludur.'));
    }
    return guardFailure(() async {
      await _repository.addCourse(course);
      return unit;
    });
  }

  Future<Either<Failure, Unit>> remove(String courseId) => guardFailure(() async {
        await _repository.removeCourse(courseId);
        return unit;
      });
}
