import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/utils/grade_calculator.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/submission_entity.dart';
import '../repositories/assignment_repository.dart';

/// Eğitmenin teslimi puanlaması ve yazılı geri bildirim vermesi.
/// Geç teslimlerde ceza [SubmissionEntity.finalScore] üzerinden otomatik uygulanır.
class GradeAndFeedbackUseCase {
  const GradeAndFeedbackUseCase(this._repository);

  final AssignmentRepository _repository;

  Future<SubmissionEntity> call({
    required UserEntity actor,
    required String submissionId,
    required double score,
    String? writtenFeedback,
  }) {
    RoleGuard.requireInstructor(actor.role);
    if (!GradeCalculator.isValidScore(score)) throw const ValidationFailure(AppStrings.scoreRangeError);
    return _repository.gradeSubmission(
      submissionId: submissionId,
      score: score,
      writtenFeedback: writtenFeedback?.trim(),
    );
  }
}
