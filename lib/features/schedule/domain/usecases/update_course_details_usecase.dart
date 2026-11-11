import '../../../../core/enums/user_role.dart';
import '../../../../core/router/role_guard.dart';
import '../entities/course_schedule_entity.dart';
import '../repositories/schedule_repository.dart';
import 'add_or_remove_course_usecase.dart';

/// Mevcut dersin saat, sınıf veya eğitmen bilgisini günceller (yalnızca eğitmen).
class UpdateCourseDetailsUseCase {
  const UpdateCourseDetailsUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<CourseScheduleEntity> call({required UserRole actorRole, required CourseScheduleEntity course}) {
    RoleGuard.requireInstructor(actorRole);
    AddOrRemoveCourseUseCase.validateCourse(course);
    return _repository.saveCourse(course);
  }
}
