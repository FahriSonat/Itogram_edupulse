import 'package:equatable/equatable.dart';

import '../../../../core/enums/submission_status.dart';
import '../../../../core/utils/grade_calculator.dart';

/// [SubmissionEntity] öğrencinin ödev teslimi, eğitmen puanı ve geri bildirimi.
class SubmissionEntity extends Equatable {
  final String id;
  final String assignmentId;
  final String studentUid;
  final String studentName;
  final String studentNo;
  final String fileName;
  final int fileSizeBytes;
  final DateTime submittedAt;

  /// Kural 2: Son teslim tarihinden sonra yüklendiyse true (-10 puan).
  final bool isLate;

  /// Eğitmenin verdiği ham puan (ceza öncesi). Null: henüz değerlendirilmedi.
  final double? score;
  final String? writtenFeedback;
  final String? audioFeedbackUrl;
  final DateTime? gradedAt;

  const SubmissionEntity({
    required this.id,
    required this.assignmentId,
    required this.studentUid,
    required this.studentName,
    required this.studentNo,
    required this.fileName,
    required this.fileSizeBytes,
    required this.submittedAt,
    required this.isLate,
    this.score,
    this.writtenFeedback,
    this.audioFeedbackUrl,
    this.gradedAt,
  });

  bool get isGraded => score != null;

  /// Geç teslim cezası uygulanmış puan.
  double? get finalScore => score == null ? null : GradeCalculator.applyLatePenalty(score!, isLate: isLate);

  SubmissionStatus get status => isLate ? SubmissionStatus.late : SubmissionStatus.submitted;

  SubmissionEntity copyWith({double? score, String? writtenFeedback, DateTime? gradedAt}) => SubmissionEntity(
    id: id,
    assignmentId: assignmentId,
    studentUid: studentUid,
    studentName: studentName,
    studentNo: studentNo,
    fileName: fileName,
    fileSizeBytes: fileSizeBytes,
    submittedAt: submittedAt,
    isLate: isLate,
    score: score ?? this.score,
    writtenFeedback: writtenFeedback ?? this.writtenFeedback,
    audioFeedbackUrl: audioFeedbackUrl,
    gradedAt: gradedAt ?? this.gradedAt,
  );

  @override
  List<Object?> get props => [
    id,
    assignmentId,
    studentUid,
    studentName,
    studentNo,
    fileName,
    fileSizeBytes,
    submittedAt,
    isLate,
    score,
    writtenFeedback,
    audioFeedbackUrl,
    gradedAt,
  ];
}
