import 'package:equatable/equatable.dart';

import '../../../../core/enums/submission_status.dart';
import '../../../../core/enums/view_status.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/submission_entity.dart';

/// Devam eden / son tamamlanan dosya yüklemesi.
class UploadProgress extends Equatable {
  final String assignmentId;
  final String fileName;
  final String fileSize;
  final double progress;
  final bool isCompleted;
  final String? errorMessage;

  const UploadProgress({
    required this.assignmentId,
    required this.fileName,
    required this.fileSize,
    this.progress = 0,
    this.isCompleted = false,
    this.errorMessage,
  });

  bool get isUploading => !isCompleted && errorMessage == null;

  UploadProgress copyWith({double? progress, bool? isCompleted, String? errorMessage}) => UploadProgress(
    assignmentId: assignmentId,
    fileName: fileName,
    fileSize: fileSize,
    progress: progress ?? this.progress,
    isCompleted: isCompleted ?? this.isCompleted,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [assignmentId, fileName, fileSize, progress, isCompleted, errorMessage];
}

class AssignmentState extends Equatable {
  final ViewStatus status;
  final List<AssignmentEntity> assignments;
  final List<SubmissionEntity> submissions;
  final UploadProgress? upload;
  final String? errorMessage;

  const AssignmentState({
    this.status = ViewStatus.initial,
    this.assignments = const [],
    this.submissions = const [],
    this.upload,
    this.errorMessage,
  });

  SubmissionEntity? submissionFor(String assignmentId, String studentUid) {
    for (final s in submissions) {
      if (s.assignmentId == assignmentId && s.studentUid == studentUid) return s;
    }
    return null;
  }

  List<SubmissionEntity> submissionsFor(String assignmentId) =>
      submissions.where((s) => s.assignmentId == assignmentId).toList();

  AssignmentEntity? assignmentById(String id) {
    for (final a in assignments) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Öğrenci kartındaki durum: teslim edildiyse "Teslim Edildi", değilse
  /// süre geçtiyse "Gecikti", aksi halde "Bekliyor".
  SubmissionStatus statusFor(AssignmentEntity assignment, String studentUid) {
    if (submissionFor(assignment.id, studentUid) != null) return SubmissionStatus.submitted;
    return assignment.isPastDue() ? SubmissionStatus.late : SubmissionStatus.pending;
  }

  /// Öğrencinin henüz teslim etmediği ödevler.
  List<AssignmentEntity> openAssignmentsFor(String studentUid) =>
      assignments.where((a) => submissionFor(a.id, studentUid) == null).toList();

  bool hasOverdueFor(String studentUid) => openAssignmentsFor(studentUid).any((a) => a.isPastDue());

  /// Eğitmen paneli: değerlendirilmeyi bekleyen teslim sayısı.
  int get pendingGradingCount => submissions.where((s) => !s.isGraded).length;

  AssignmentState copyWith({
    ViewStatus? status,
    List<AssignmentEntity>? assignments,
    List<SubmissionEntity>? submissions,
    UploadProgress? Function()? upload,
    String? errorMessage,
  }) => AssignmentState(
    status: status ?? this.status,
    assignments: assignments ?? this.assignments,
    submissions: submissions ?? this.submissions,
    upload: upload != null ? upload() : this.upload,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, assignments, submissions, upload, errorMessage];
}
