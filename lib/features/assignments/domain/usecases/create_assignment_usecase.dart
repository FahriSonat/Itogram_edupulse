import '../../../../core/error/failures.dart';
import '../../../../core/router/role_guard.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/assignment_entity.dart';
import '../repositories/assignment_repository.dart';

/// Eğitmenin rubrikli yeni ödev yayınlaması (Kural 5).
class CreateAssignmentUseCase {
  const CreateAssignmentUseCase(this._repository);

  final AssignmentRepository _repository;

  Future<AssignmentEntity> call({
    required UserEntity actor,
    required String courseName,
    required String title,
    required String description,
    required String rubricCriteria,
    required DateTime dueDate,
  }) {
    RoleGuard.requireInstructor(actor.role);
    if (title.trim().isEmpty) throw const ValidationFailure('Ödev başlığı boş olamaz.');
    if (!dueDate.isAfter(DateTime.now())) {
      throw const ValidationFailure('Son teslim tarihi ileri bir tarih olmalıdır.');
    }
    return _repository.createAssignment(
      courseName: courseName,
      title: title.trim(),
      description: description.trim(),
      rubricCriteria: rubricCriteria.trim(),
      dueDate: dueDate,
      author: actor,
    );
  }
}
