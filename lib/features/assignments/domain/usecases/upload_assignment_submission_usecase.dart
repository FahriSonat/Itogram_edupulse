import '../../../../core/error/failures.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/assignment_entity.dart';
import '../entities/submission_entity.dart';
import '../repositories/assignment_repository.dart';

/// Kural 2 (Ödev Zaman Kalkanı): Son teslim tarihinden sonra yapılan teslim
/// kabul edilir ancak `isLate` olarak işaretlenir ve değerlendirmede 10 puan düşülür.
class UploadAssignmentSubmissionUseCase {
  const UploadAssignmentSubmissionUseCase(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AssignmentRepository _repository;
  final DateTime Function() _clock;

  static const int maxFileBytes = 50 * 1024 * 1024;

  Future<SubmissionEntity> call({
    required UserEntity actor,
    required AssignmentEntity assignment,
    required PickedFileInfo file,
    required void Function(double progress) onProgress,
  }) {
    RoleGuard.requireStudent(actor.role);
    if (file.sizeBytes > maxFileBytes) {
      throw const ValidationFailure('Dosya boyutu 50 MB sınırını aşıyor.');
    }
    final existing = _repository.findSubmission(assignmentId: assignment.id, studentUid: actor.uid);
    if (existing != null && existing.isGraded) {
      throw const ValidationFailure('Bu ödev değerlendirildiği için yeniden teslim edilemez.');
    }
    return _repository.uploadSubmission(
      assignment: assignment,
      student: actor,
      file: file,
      isLate: assignment.isPastDue(_clock()),
      onProgress: onProgress,
    );
  }
}
