import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/assignment_entity.dart';
import '../repositories/assignment_repository.dart';

/// Eğitmen için yeni ödev + rubrik açar; ödevleri ders bazında izler.
class CreateAssignmentUseCase {
  const CreateAssignmentUseCase(this._repository);

  final AssignmentRepository _repository;

  Future<Either<Failure, Unit>> call(AssignmentEntity assignment) async {
    if (assignment.title.trim().isEmpty) {
      return const Left(ServerFailure('Ödev başlığı zorunludur.'));
    }
    return guardFailure(() async {
      await _repository.createAssignment(assignment);
      return unit;
    });
  }

  Stream<Either<Failure, List<AssignmentEntity>>> watch(String courseId) =>
      guardStream(_repository.watchAssignments(courseId));
}
