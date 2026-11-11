import 'dart:io';
import 'dart:typed_data';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/analytics_service.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/submission_entity.dart';
import '../../domain/repositories/assignment_repository.dart';
import '../datasources/assignment_remote_datasource.dart';
import '../datasources/assignment_storage_datasource.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';

export '../datasources/assignment_storage_datasource.dart'
    show StorageUploadProgressEvent;

class AssignmentRepositoryImpl implements AssignmentRepository {
  final AssignmentRemoteDataSource _remoteDataSource;
  final AssignmentStorageDataSource _storageDataSource;
  final NetworkInfo _networkInfo;
  final AnalyticsService? analyticsService;

  AssignmentRepositoryImpl({
    AssignmentRemoteDataSource? remoteDataSource,
    AssignmentStorageDataSource? storageDataSource,
    NetworkInfo? networkInfo,
    this.analyticsService,
  })  : _remoteDataSource =
            remoteDataSource ?? AssignmentRemoteDataSourceImpl(),
        _storageDataSource =
            storageDataSource ?? AssignmentStorageDataSourceImpl(),
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  @override
  Stream<List<AssignmentEntity>> watchAssignments(String courseId) {
    return _remoteDataSource.watchAssignments(courseId);
  }

  @override
  Future<void> createAssignment(AssignmentEntity assignment) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final model = assignment is AssignmentModel
        ? assignment
        : AssignmentModel(
            assignmentId: assignment.assignmentId,
            courseId: assignment.courseId,
            courseName: assignment.courseName,
            title: assignment.title,
            description: assignment.description,
            rubricCriteria: assignment.rubricCriteria,
            dueDate: assignment.dueDate,
          );

    await _remoteDataSource.createAssignment(model);
  }

  @override
  Stream<List<SubmissionEntity>> watchSubmissions(String assignmentId) {
    return _remoteDataSource.watchSubmissions(assignmentId);
  }

  @override
  Future<void> uploadSubmission(SubmissionEntity submission) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    String resolvedFileUrl = submission.fileUrl;

    // Eğer fileUrl yerel bir dosya yoluysa önce Firebase Storage'a yükle
    if (resolvedFileUrl.isNotEmpty &&
        !resolvedFileUrl.startsWith('http://') &&
        !resolvedFileUrl.startsWith('https://')) {
      final localFile = File(resolvedFileUrl);
      if (await localFile.exists()) {
        resolvedFileUrl = await _storageDataSource.uploadSubmissionFile(
          assignmentId: submission.assignmentId,
          studentId: submission.studentUid,
          fileName: submission.fileName,
          file: localFile,
        );
      }
    }

    final model = SubmissionModel(
      submissionId: submission.submissionId.isNotEmpty
          ? submission.submissionId
          : submission.studentUid,
      assignmentId: submission.assignmentId,
      studentUid: submission.studentUid,
      studentName: submission.studentName,
      fileUrl: resolvedFileUrl,
      fileName: submission.fileName,
      submittedAt: submission.submittedAt,
      status: submission.status,
      isLatePenaltyApplied: submission.isLatePenaltyApplied,
      rawScore: submission.rawScore,
      finalScore: submission.finalScore,
      writtenFeedback: submission.writtenFeedback,
      audioFeedbackUrl: submission.audioFeedbackUrl,
    );

    await _remoteDataSource.uploadSubmission(model);

    await analyticsService?.logAssignmentSubmitted(
      assignmentId: submission.assignmentId,
      isLate: submission.isLatePenaltyApplied,
      fileName: submission.fileName,
    );
  }

  /// Öğrencinin seçtiği dosya/görseli Firebase Storage'a yüklerken
  /// `UploadTask.snapshotEvents` üzerinden anlık yükleme yüzdesini (0% -> 100%)
  /// `Stream<double>` olarak verir.
  Stream<StorageUploadProgressEvent> watchSubmissionFileUpload({
    required String assignmentId,
    required String studentUid,
    required String fileName,
    File? file,
    Uint8List? fileBytes,
  }) {
    return _storageDataSource.watchSubmissionFileUpload(
      assignmentId: assignmentId,
      studentId: studentUid,
      fileName: fileName,
      file: file,
      fileBytes: fileBytes,
    );
  }

  @override
  Future<void> gradeSubmission({
    required String assignmentId,
    required String submissionId,
    required double rawScore,
    String? writtenFeedback,
    String? audioFeedbackUrl,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    String? resolvedAudioUrl = audioFeedbackUrl;

    // Eğer audioFeedbackUrl yerel bir ses dosyası yoluysa önce Storage'a yükle
    if (resolvedAudioUrl != null &&
        resolvedAudioUrl.isNotEmpty &&
        !resolvedAudioUrl.startsWith('http://') &&
        !resolvedAudioUrl.startsWith('https://')) {
      final localAudioFile = File(resolvedAudioUrl);
      if (await localAudioFile.exists()) {
        resolvedAudioUrl =
            await _storageDataSource.uploadInstructorAudioFeedback(
          assignmentId: assignmentId,
          submissionId: submissionId,
          fileName: 'feedback_$submissionId.m4a',
          audioFile: localAudioFile,
        );
      }
    }

    await _remoteDataSource.gradeSubmission(
      assignmentId: assignmentId,
      submissionId: submissionId,
      rawScore: rawScore,
      writtenFeedback: writtenFeedback,
      audioFeedbackUrl: resolvedAudioUrl,
    );
  }
}
