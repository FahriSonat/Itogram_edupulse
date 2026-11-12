import 'package:equatable/equatable.dart';
import '../../../../core/enums/submission_status.dart';

class SubmissionEntity extends Equatable {
  final String submissionId;
  final String assignmentId;
  final String studentUid;
  final String studentName;
  final String fileUrl;
  final String fileName;
  final DateTime submittedAt;
  final SubmissionStatus status;
  final bool isLatePenaltyApplied;
  final double? rawScore;
  final double? finalScore;
  final String? writtenFeedback;
  final String? audioFeedbackUrl;

  const SubmissionEntity({
    required this.submissionId,
    required this.assignmentId,
    required this.studentUid,
    required this.studentName,
    required this.fileUrl,
    required this.fileName,
    required this.submittedAt,
    required this.status,
    required this.isLatePenaltyApplied,
    this.rawScore,
    this.finalScore,
    this.writtenFeedback,
    this.audioFeedbackUrl,
  });

  @override
  List<Object?> get props => [
        submissionId,
        assignmentId,
        studentUid,
        studentName,
        fileUrl,
        fileName,
        submittedAt,
        status,
        isLatePenaltyApplied,
        rawScore,
        finalScore,
        writtenFeedback,
        audioFeedbackUrl,
      ];
}