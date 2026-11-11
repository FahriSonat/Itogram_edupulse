import 'package:equatable/equatable.dart';

import '../../../../core/enums/view_status.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/submission_entity.dart';

/// Storage yükleme ilerlemesi (öğrenci teslim masası).
class UploadProgress extends Equatable {
  const UploadProgress({
    required this.assignmentId,
    required this.fileName,
    this.progress = 0,
    this.isUploading = true,
    this.isCompleted = false,
    this.isLate = false,
    this.errorMessage,
  });

  final String assignmentId;
  final String fileName;

  /// 0.0 → 1.0 (UploadTask.snapshotEvents).
  final double progress;
  final bool isUploading;
  final bool isCompleted;

  /// Kural 2: son teslimden sonra yüklendi → -10 ceza.
  final bool isLate;
  final String? errorMessage;

  @override
  List<Object?> get props => <Object?>[assignmentId, fileName, progress, isUploading, isCompleted, isLate, errorMessage];
}

class AssignmentState extends Equatable {
  const AssignmentState({
    this.status = ViewStatus.initial,
    this.courses = const <CourseScheduleEntity>[],
    this.selectedCourseId,
    this.assignments = const <AssignmentEntity>[],
    this.openAssignmentId,
    this.submissions = const <SubmissionEntity>[],
    this.submissionsStatus = ViewStatus.initial,
    this.upload,
    this.isRecording = false,
    this.recordedAudioPath,
    this.isGrading = false,
    this.errorMessage,
    this.actionMessage,
  });

  final ViewStatus status;
  final List<CourseScheduleEntity> courses;
  final String? selectedCourseId;
  final List<AssignmentEntity> assignments;

  /// Teslimleri izlenen ödev (eğitmen listesi / öğrencinin kendi teslimi).
  final String? openAssignmentId;
  final List<SubmissionEntity> submissions;
  final ViewStatus submissionsStatus;

  final UploadProgress? upload;
  final bool isRecording;
  final String? recordedAudioPath;
  final bool isGrading;
  final String? errorMessage;
  final String? actionMessage;

  CourseScheduleEntity? get selectedCourse {
    for (final c in courses) {
      if (c.courseId == selectedCourseId) return c;
    }
    return null;
  }

  SubmissionEntity? submissionOf(String studentUid) {
    for (final s in submissions) {
      if (s.studentUid == studentUid) return s;
    }
    return null;
  }

  SubmissionEntity? submissionById(String submissionId) {
    for (final s in submissions) {
      if (s.submissionId == submissionId) return s;
    }
    return null;
  }

  AssignmentState copyWith({
    ViewStatus? status,
    List<CourseScheduleEntity>? courses,
    String? selectedCourseId,
    List<AssignmentEntity>? assignments,
    String? openAssignmentId,
    List<SubmissionEntity>? submissions,
    ViewStatus? submissionsStatus,
    UploadProgress? upload,
    bool clearUpload = false,
    bool? isRecording,
    String? recordedAudioPath,
    bool clearRecording = false,
    bool? isGrading,
    String? errorMessage,
    String? actionMessage,
  }) {
    return AssignmentState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      selectedCourseId: selectedCourseId ?? this.selectedCourseId,
      assignments: assignments ?? this.assignments,
      openAssignmentId: openAssignmentId ?? this.openAssignmentId,
      submissions: submissions ?? this.submissions,
      submissionsStatus: submissionsStatus ?? this.submissionsStatus,
      upload: clearUpload ? null : (upload ?? this.upload),
      isRecording: isRecording ?? this.isRecording,
      recordedAudioPath: clearRecording ? null : (recordedAudioPath ?? this.recordedAudioPath),
      isGrading: isGrading ?? this.isGrading,
      errorMessage: errorMessage,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        courses,
        selectedCourseId,
        assignments,
        openAssignmentId,
        submissions,
        submissionsStatus,
        upload,
        isRecording,
        recordedAudioPath,
        isGrading,
        errorMessage,
        actionMessage,
      ];
}
