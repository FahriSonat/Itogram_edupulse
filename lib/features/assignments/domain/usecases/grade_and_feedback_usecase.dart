import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../../../../core/utils/grade_calculator.dart';
import '../entities/submission_entity.dart';
import '../repositories/assignment_repository.dart';

/// Eğitmenin teslimi 100 üzerinden puanlaması + yazılı / sesli geribildirim.
/// Gecikmiş teslimde -10 ceza GradeCalculator ile uygulanır (Kural 2).
class GradeAndFeedbackUseCase {
  const GradeAndFeedbackUseCase(this._repository);

  final AssignmentRepository _repository;

  /// Öğrencinin göreceği nihai puan (önizleme için).
  static double previewFinalScore(double rawScore, {required bool isLate}) =>
      GradeCalculator.applyLatePenalty(rawScore.clamp(0, 100).toDouble(), isLate);

  Stream<Either<Failure, List<SubmissionEntity>>> watchSubmissions(String assignmentId) =>
      guardStream(_repository.watchSubmissions(assignmentId));

  Future<Either<Failure, Unit>> call({
    required String assignmentId,
    required String submissionId,
    required double rawScore,
    String? writtenFeedback,
    String? localAudioPath,
  }) async {
    if (rawScore < 0 || rawScore > 100) {
      return const Left(ServerFailure('Puan 0 ile 100 arasında olmalıdır.'));
    }
    return guardFailure(() async {
      String? audioUrl;
      if (localAudioPath != null && localAudioPath.isNotEmpty) {
        audioUrl = await _repository.uploadAudioFeedback(
          assignmentId: assignmentId,
          submissionId: submissionId,
          localFilePath: localAudioPath,
        );
      }
      await _repository.gradeSubmission(
        assignmentId: assignmentId,
        submissionId: submissionId,
        rawScore: rawScore,
        writtenFeedback: writtenFeedback,
        audioFeedbackUrl: audioUrl,
      );
      return unit;
    });
  }
}
