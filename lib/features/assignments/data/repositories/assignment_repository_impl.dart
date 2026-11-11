import 'dart:io';
import 'dart:typed_data';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/analytics_service.dart';
import '../datasources/assignment_remote_datasource.dart';
import '../datasources/assignment_storage_datasource.dart';

export '../datasources/assignment_storage_datasource.dart'
    show StorageUploadProgressEvent;

class AssignmentRepositoryImpl {
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

  Stream<List<Map<String, dynamic>>> watchAssignments({String? courseId}) {
    return _remoteDataSource.watchAssignments(courseId: courseId);
  }

  Future<Map<String, dynamic>> createAssignment({
    required String courseId,
    required String courseName,
    required String title,
    required String description,
    required DateTime dueDate,
    required String instructorId,
    bool allowLateSubmission = true,
    int maxScore = 100,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    return _remoteDataSource.createAssignment(
      courseId: courseId,
      courseName: courseName,
      title: title,
      description: description,
      dueDate: dueDate,
      instructorId: instructorId,
      allowLateSubmission: allowLateSubmission,
      maxScore: maxScore,
    );
  }

  Stream<List<Map<String, dynamic>>> watchSubmissions(String assignmentId) {
    return _remoteDataSource.watchSubmissions(assignmentId);
  }

  Future<Map<String, dynamic>?> getStudentSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    return _remoteDataSource.getStudentSubmission(
      assignmentId: assignmentId,
      studentId: studentId,
    );
  }

  /// Öğrencinin seçtiği dosya/görseli Firebase Storage'a yüklerken
  /// `UploadTask.snapshotEvents` üzerinden anlık yükleme yüzdesini (0% -> 100%)
  /// `Stream<double>` olarak verir ve tamamlandığında Firestore `submissions` dökümanına yazar.
  Stream<double> watchAssignmentSubmissionUpload({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String studentNo,
    required String fileName,
    required DateTime dueDate,
    File? file,
    Uint8List? fileBytes,
    String? studentNote,
  }) async* {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    await for (final event in _storageDataSource.watchSubmissionFileUpload(
      assignmentId: assignmentId,
      studentId: studentId,
      fileName: fileName,
      file: file,
      fileBytes: fileBytes,
    )) {
      yield event.percentage;

      if (event.isCompleted && event.downloadUrl != null) {
        await _remoteDataSource.saveSubmission(
          assignmentId: assignmentId,
          studentId: studentId,
          studentName: studentName,
          studentNo: studentNo,
          fileUrl: event.downloadUrl!,
          fileName: fileName,
          dueDate: dueDate,
          studentNote: studentNote,
        );

        await analyticsService?.logAssignmentSubmitted(
          assignmentId: assignmentId,
          isLate: DateTime.now().isAfter(dueDate),
          fileName: fileName,
        );
      }
    }
  }

  /// Ödev dosyasını Firebase Storage'a yükler, ilerleme durumunu [onProgress] ile iletir
  /// ve teslim bilgisini Firestore'a kaydeder.
  Future<Map<String, dynamic>> uploadAssignmentSubmission({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String studentNo,
    required String fileName,
    required DateTime dueDate,
    File? file,
    Uint8List? fileBytes,
    String? studentNote,
    void Function(double progress)? onProgress,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final downloadUrl = await _storageDataSource.uploadSubmissionFile(
      assignmentId: assignmentId,
      studentId: studentId,
      fileName: fileName,
      file: file,
      fileBytes: fileBytes,
      onProgress: onProgress,
    );

    final submission = await _remoteDataSource.saveSubmission(
      assignmentId: assignmentId,
      studentId: studentId,
      studentName: studentName,
      studentNo: studentNo,
      fileUrl: downloadUrl,
      fileName: fileName,
      dueDate: dueDate,
      studentNote: studentNote,
    );

    await analyticsService?.logAssignmentSubmitted(
      assignmentId: assignmentId,
      isLate: DateTime.now().isAfter(dueDate),
      fileName: fileName,
    );

    return submission;
  }

  /// Eğitmenin kaydettiği sesli geribildirimi Storage'a yükler ve URL'sini
  /// yazılı geri bildirim ve not ile birlikte Firestore `submissions` dökümanına yazar.
  Future<Map<String, dynamic>> gradeAndProvideFeedback({
    required String assignmentId,
    required String submissionId,
    required double score,
    String? writtenFeedback,
    File? audioFeedbackFile,
    Uint8List? audioFeedbackBytes,
    String? existingAudioFeedbackUrl,
    void Function(double progress)? onAudioUploadProgress,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    String? audioUrl = existingAudioFeedbackUrl;
    if (audioFeedbackFile != null || audioFeedbackBytes != null) {
      audioUrl = await _storageDataSource.uploadInstructorAudioFeedback(
        assignmentId: assignmentId,
        submissionId: submissionId,
        fileName: 'feedback_$submissionId.m4a',
        audioFile: audioFeedbackFile,
        audioBytes: audioFeedbackBytes,
        onProgress: onAudioUploadProgress,
      );
    }

    return _remoteDataSource.gradeAndProvideFeedback(
      assignmentId: assignmentId,
      submissionId: submissionId,
      score: score,
      writtenFeedback: writtenFeedback,
      audioFeedbackUrl: audioUrl,
    );
  }
}
