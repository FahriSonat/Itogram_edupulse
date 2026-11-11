import '../../../../core/services/file_picker_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/assignment_entity.dart';
import '../entities/submission_entity.dart';

abstract class AssignmentRepository {
  Stream<List<AssignmentEntity>> watchAssignments();

  Stream<List<SubmissionEntity>> watchSubmissions();

  Future<AssignmentEntity> createAssignment({
    required String courseName,
    required String title,
    required String description,
    required String rubricCriteria,
    required DateTime dueDate,
    required UserEntity author,
  });

  /// Dosyayı depolamaya yükler ve teslim kaydını oluşturur / günceller.
  Future<SubmissionEntity> uploadSubmission({
    required AssignmentEntity assignment,
    required UserEntity student,
    required PickedFileInfo file,
    required bool isLate,
    required void Function(double progress) onProgress,
  });

  SubmissionEntity? findSubmission({required String assignmentId, required String studentUid});

  Future<SubmissionEntity> gradeSubmission({
    required String submissionId,
    required double score,
    String? writtenFeedback,
  });
}
