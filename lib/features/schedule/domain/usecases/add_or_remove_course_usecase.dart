import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/utils/validators.dart';
import '../entities/course_schedule_entity.dart';
import '../repositories/schedule_repository.dart';

/// Eğitmenin programa yeni ders eklemesi veya ders silmesi (Kural 5).
class AddOrRemoveCourseUseCase {
  const AddOrRemoveCourseUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<CourseScheduleEntity> add({required UserRole actorRole, required CourseScheduleEntity course}) {
    RoleGuard.requireInstructor(actorRole);
    validateCourse(course);
    return _repository.saveCourse(course.copyWith(id: ''));
  }

  Future<void> remove({required UserRole actorRole, required String courseId}) {
    RoleGuard.requireInstructor(actorRole);
    return _repository.removeCourse(courseId);
  }

  /// Saat biçimi ve başlangıç < bitiş kontrolü.
  static void validateCourse(CourseScheduleEntity course) {
    final timeError = Validators.time(course.startTime) ?? Validators.time(course.endTime);
    if (timeError != null) throw ValidationFailure(timeError);
    if (course.endMinutes <= course.startMinutes) {
      throw const ValidationFailure('Bitiş saati başlangıç saatinden sonra olmalıdır.');
    }
    if (course.dayOfWeek < 1 || course.dayOfWeek > 7) {
      throw const ValidationFailure('Geçersiz gün seçimi.');
    }
  }
}
