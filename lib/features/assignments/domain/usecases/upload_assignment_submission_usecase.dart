import 'package:dartz/dartz.dart';

import '../../../../core/enums/submission_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/assignment_entity.dart';
import '../entities/submission_entity.dart';
import '../repositories/assignment_repository.dart';

/// Kural 2 Uygulayıcısı: son teslim tarihi geçmişse yüklemeyi ENGELLEMEZ;
/// durumu [SubmissionStatus.late] yapar ve -10 ceza bayrağını çakar.
class UploadAssignmentSubmissionUseCase {
  const UploadAssignmentSubmissionUseCase(this._repository);

  final AssignmentRepository _repository;

  /// Teslim nesnesini Kural 2'ye göre hazırlar (saf fonksiyon — test edilebilir).
  static SubmissionEntity buildSubmission({
    required AssignmentEntity assignment,
    required String studentUid,
    required String studentName,
    required String localFilePath,
    required String fileName,
    required DateTime submittedAt,
  }) {
    final isLate = submittedAt.isAfter(assignment.dueDate);
    return SubmissionEntity(
      submissionId: studentUid,
      assignmentId: assignment.assignmentId,
      studentUid: studentUid,
      studentName: studentName,
      fileUrl: localFilePath,
      fileName: fileName,
      submittedAt: submittedAt,
      status: isLate ? SubmissionStatus.late : SubmissionStatus.submitted,
      isLatePenaltyApplied: isLate,
    );
  }

  /// Kural 2 kontrolüyle yükleme yapar ve anlık ilerlemeyi (0.0 → 1.0) yayar.
  /// Hata olursa akış `Left(Failure)` ile biter.
  Stream<Either<Failure, double>> withProgress({
    required AssignmentEntity assignment,
    required String studentUid,
    required String studentName,
    required String localFilePath,
    required String fileName,
    DateTime? now,
  }) {
    if (localFilePath.isEmpty) {
      return Stream.value(const Left(ServerFailure('Yüklenecek dosya seçilmedi.')));
    }
    final submission = buildSubmission(
      assignment: assignment,
      studentUid: studentUid,
      studentName: studentName,
      localFilePath: localFilePath,
      fileName: fileName,
      submittedAt: now ?? DateTime.now(),
    );
    return guardStream(_repository.uploadSubmissionWithProgress(submission));
  }

  Future<Either<Failure, SubmissionEntity>> call({
    required AssignmentEntity assignment,
    required String studentUid,
    required String studentName,
    required String localFilePath,
    required String fileName,
    DateTime? now,
  }) async {
    if (localFilePath.isEmpty) {
      return const Left(ServerFailure('Yüklenecek dosya seçilmedi.'));
    }
    final submission = buildSubmission(
      assignment: assignment,
      studentUid: studentUid,
      studentName: studentName,
      localFilePath: localFilePath,
      fileName: fileName,
      submittedAt: now ?? DateTime.now(),
    );
    return guardFailure(() async {
      await _repository.uploadSubmission(submission);
      return submission;
    });
  }
}
