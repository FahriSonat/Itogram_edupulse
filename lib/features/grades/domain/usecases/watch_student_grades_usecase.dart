import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/course_grade_entity.dart';
import '../repositories/grades_repository.dart';

/// Öğrencinin kendi notlarını / eğitmenin bir dersteki tüm notlarını canlı izler.
class WatchStudentGradesUseCase {
  const WatchStudentGradesUseCase(this._repository);

  final GradesRepository _repository;

  Stream<Either<Failure, List<CourseGradeEntity>>> call(String studentUid) =>
      guardStream(_repository.watchStudentGrades(studentUid));

  Stream<Either<Failure, List<CourseGradeEntity>>> course(String courseId) =>
      guardStream(_repository.watchCourseGrades(courseId));
}
