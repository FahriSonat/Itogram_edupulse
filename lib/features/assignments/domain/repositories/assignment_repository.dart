import '../entities/assignment_entity.dart';
import '../entities/submission_entity.dart';

abstract class AssignmentRepository {
  Stream<List<AssignmentEntity>> watchAssignments(String courseId);
  
  Future<void> createAssignment(AssignmentEntity assignment);
  
  Stream<List<SubmissionEntity>> watchSubmissions(String assignmentId);
  
  Future<void> uploadSubmission(SubmissionEntity submission);

  /// Yerel dosyayı Storage'a yüklerken anlık ilerlemeyi (0.0 → 1.0) yayar;
  /// yükleme bitince teslim kaydını Firestore'a yazar ve akış tamamlanır.
  Stream<double> uploadSubmissionWithProgress(SubmissionEntity submission);
  
  Future<void> gradeSubmission({
    required String assignmentId,
    required String submissionId,
    required double rawScore,
    String? writtenFeedback,
    String? audioFeedbackUrl,
  });

  /// Eğitmenin kaydettiği sesli geribildirimi Storage'a yükler, URL döner.
  Future<String> uploadAudioFeedback({
    required String assignmentId,
    required String submissionId,
    required String localFilePath,
  });
}