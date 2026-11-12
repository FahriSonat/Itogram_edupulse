import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/submission_entity.dart';
import '../../../../core/enums/submission_status.dart';

class SubmissionModel extends SubmissionEntity {
  const SubmissionModel({
    required super.submissionId,
    required super.assignmentId,
    required super.studentUid,
    required super.studentName,
    required super.fileUrl,
    required super.fileName,
    required super.submittedAt,
    required super.status,
    required super.isLatePenaltyApplied,
    super.rawScore,
    super.finalScore,
    super.writtenFeedback,
    super.audioFeedbackUrl,
  });

  factory SubmissionModel.fromFirestore(Map<String, dynamic> json, String id) {
    final rawSubmitted = json['submittedAt'];
    final DateTime submittedAt = switch (rawSubmitted) {
      final Timestamp ts => ts.toDate(),
      final DateTime dt => dt,
      final String s => DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0),
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };
    return SubmissionModel(
      submissionId: id,
      assignmentId: (json['assignmentId'] ?? '').toString(),
      studentUid: (json['studentUid'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      fileUrl: (json['fileUrl'] ?? '').toString(),
      fileName: (json['fileName'] ?? '').toString(),
      submittedAt: submittedAt,
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubmissionStatus.pending,
      ),
      isLatePenaltyApplied: json['isLatePenaltyApplied'] as bool? ?? false,
      rawScore: (json['rawScore'] as num?)?.toDouble(),
      finalScore: (json['finalScore'] as num?)?.toDouble(),
      writtenFeedback: json['writtenFeedback'] as String?,
      audioFeedbackUrl: json['audioFeedbackUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'studentUid': studentUid,
      'studentName': studentName,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status.name,
      'isLatePenaltyApplied': isLatePenaltyApplied,
      'rawScore': rawScore,
      'finalScore': finalScore,
      'writtenFeedback': writtenFeedback,
      'audioFeedbackUrl': audioFeedbackUrl,
    };
  }

  SubmissionModel copyWith({
    String? submissionId,
    String? assignmentId,
    String? studentUid,
    String? studentName,
    String? fileUrl,
    String? fileName,
    DateTime? submittedAt,
    SubmissionStatus? status,
    bool? isLatePenaltyApplied,
    double? rawScore,
    double? finalScore,
    String? writtenFeedback,
    String? audioFeedbackUrl,
  }) {
    return SubmissionModel(
      submissionId: submissionId ?? this.submissionId,
      assignmentId: assignmentId ?? this.assignmentId,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      isLatePenaltyApplied: isLatePenaltyApplied ?? this.isLatePenaltyApplied,
      rawScore: rawScore ?? this.rawScore,
      finalScore: finalScore ?? this.finalScore,
      writtenFeedback: writtenFeedback ?? this.writtenFeedback,
      audioFeedbackUrl: audioFeedbackUrl ?? this.audioFeedbackUrl,
    );
  }
}