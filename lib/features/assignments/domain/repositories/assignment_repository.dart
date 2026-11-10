import '../entities/assignment_entity.dart';
import '../entities/submission_entity.dart';

abstract class AssignmentRepository {
  Stream<List<AssignmentEntity>> watchAssignments(String courseId);
  
  Future<void> createAssignment(AssignmentEntity assignment);
  
  Stream<List<SubmissionEntity>> watchSubmissions(String assignmentId);
  
  Future<void> uploadSubmission(SubmissionEntity submission);
  
  Future<void> gradeSubmission({
    required String assignmentId,
    required String submissionId,
    required double rawScore,
    String? writtenFeedback,
    String? audioFeedbackUrl,
  });
}