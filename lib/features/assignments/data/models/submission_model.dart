import '../../domain/entities/submission_entity.dart';

class SubmissionModel extends SubmissionEntity {
  const SubmissionModel({
    required super.id,
    required super.assignmentId,
    required super.studentUid,
    required super.studentName,
    required super.studentNo,
    required super.fileName,
    required super.fileSizeBytes,
    required super.submittedAt,
    required super.isLate,
    super.score,
    super.writtenFeedback,
    super.audioFeedbackUrl,
    super.gradedAt,
  });

  factory SubmissionModel.fromEntity(SubmissionEntity e) => SubmissionModel(
    id: e.id,
    assignmentId: e.assignmentId,
    studentUid: e.studentUid,
    studentName: e.studentName,
    studentNo: e.studentNo,
    fileName: e.fileName,
    fileSizeBytes: e.fileSizeBytes,
    submittedAt: e.submittedAt,
    isLate: e.isLate,
    score: e.score,
    writtenFeedback: e.writtenFeedback,
    audioFeedbackUrl: e.audioFeedbackUrl,
    gradedAt: e.gradedAt,
  );

  factory SubmissionModel.fromJson(Map<String, dynamic> json) => SubmissionModel(
    id: json['id'] as String,
    assignmentId: json['assignmentId'] as String? ?? '',
    studentUid: json['studentUid'] as String? ?? '',
    studentName: json['studentName'] as String? ?? '',
    studentNo: json['studentNo'] as String? ?? '',
    fileName: json['fileName'] as String? ?? '',
    fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
    submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ?? DateTime.now(),
    isLate: json['isLate'] as bool? ?? false,
    score: (json['score'] as num?)?.toDouble(),
    writtenFeedback: json['writtenFeedback'] as String?,
    audioFeedbackUrl: json['audioFeedbackUrl'] as String?,
    gradedAt: DateTime.tryParse(json['gradedAt'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'assignmentId': assignmentId,
    'studentUid': studentUid,
    'studentName': studentName,
    'studentNo': studentNo,
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'submittedAt': submittedAt.toIso8601String(),
    'isLate': isLate,
    'score': score,
    'writtenFeedback': writtenFeedback,
    'audioFeedbackUrl': audioFeedbackUrl,
    'gradedAt': gradedAt?.toIso8601String(),
  };
}
