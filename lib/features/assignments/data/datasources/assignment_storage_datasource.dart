import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Öğrencinin seçtiği dosya/görseli Firebase Storage'a yüklerken
/// `UploadTask.snapshotEvents` üzerinden anlık yükleme yüzdesini (0% -> 100%)
/// `Stream` olarak verir. Eğitmenin kaydettiği sesli geribildirimi de Storage'a yükler.
class StorageUploadProgressEvent {
  /// 0.0 ile 100.0 arasında anlık yükleme yüzdesi
  final double percentage;

  /// 0.0 ile 1.0 arasında normalize ilerleme oranı
  final double progress;

  /// Yükleme tamamlandığında oluşan indirme URL'si
  final String? downloadUrl;

  final bool isCompleted;

  const StorageUploadProgressEvent({
    required this.percentage,
    required this.progress,
    this.downloadUrl,
    this.isCompleted = false,
  });
}

abstract class AssignmentStorageDataSource {
  /// Öğrencinin seçtiği dosya/görseli Firebase Storage'a yüklerken
  /// `UploadTask.snapshotEvents` üzerinden anlık yükleme yüzdesini (0% -> 100%)
  /// `Stream<StorageUploadProgressEvent>` olarak verir.
  Stream<StorageUploadProgressEvent> watchSubmissionFileUpload({
    required String assignmentId,
    required String studentId,
    required String fileName,
    File? file,
    Uint8List? fileBytes,
    String? contentType,
  });

  /// Ödev dosyasını Firebase Storage'a yükler, anlık ilerleme yüzdesini
  /// [onProgress] ile bildirir ve yükleme tamamlandığında indirme URL'sini döner.
  Future<String> uploadSubmissionFile({
    required String assignmentId,
    required String studentId,
    required String fileName,
    File? file,
    Uint8List? fileBytes,
    String? contentType,
    void Function(double progress)? onProgress,
  });

  /// Eğitmenin kaydettiği sesli geribildirimi Firebase Storage'a yükler ve URL döner.
  Future<String> uploadInstructorAudioFeedback({
    required String assignmentId,
    required String submissionId,
    required String fileName,
    File? audioFile,
    Uint8List? audioBytes,
    void Function(double progress)? onProgress,
  });

  Future<void> deleteFileByUrl(String fileUrl);
}

class AssignmentStorageDataSourceImpl implements AssignmentStorageDataSource {
  final FirebaseStorage _storage;

  AssignmentStorageDataSourceImpl({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  UploadTask _startSubmissionUploadTask({
    required String assignmentId,
    required String studentId,
    required String fileName,
    File? file,
    Uint8List? fileBytes,
    String? contentType,
  }) {
    final safeFileName =
        '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(' ', '_')}';
    final storagePath =
        'assignments/$assignmentId/submissions/$studentId/$safeFileName';
    final ref = _storage.ref().child(storagePath);

    final metadata = SettableMetadata(
      contentType: contentType ?? _inferContentType(fileName),
      customMetadata: {
        'assignmentId': assignmentId,
        'studentId': studentId,
        'originalFileName': fileName,
      },
    );

    if (file != null) {
      return ref.putFile(file, metadata);
    } else if (fileBytes != null) {
      return ref.putData(fileBytes, metadata);
    } else {
      throw ArgumentError(
        'Yüklenecek dosya (file veya fileBytes) belirtilmelidir.',
      );
    }
  }

  @override
  Stream<StorageUploadProgressEvent> watchSubmissionFileUpload({
    required String assignmentId,
    required String studentId,
    required String fileName,
    File? file,
    Uint8List? fileBytes,
    String? contentType,
  }) async* {
    final uploadTask = _startSubmissionUploadTask(
      assignmentId: assignmentId,
      studentId: studentId,
      fileName: fileName,
      file: file,
      fileBytes: fileBytes,
      contentType: contentType,
    );

    await for (final snapshot in uploadTask.snapshotEvents) {
      final total = snapshot.totalBytes;
      final transferred = snapshot.bytesTransferred;
      final ratio = total > 0 ? (transferred / total).clamp(0.0, 1.0) : 0.0;
      final percentage = ratio * 100.0;

      if (snapshot.state == TaskState.success) {
        final url = await snapshot.ref.getDownloadURL();
        yield StorageUploadProgressEvent(
          percentage: 100.0,
          progress: 1.0,
          downloadUrl: url,
          isCompleted: true,
        );
        return;
      } else {
        yield StorageUploadProgressEvent(
          percentage: percentage,
          progress: ratio,
          isCompleted: false,
        );
      }
    }
  }

  @override
  Future<String> uploadSubmissionFile({
    required String assignmentId,
    required String studentId,
    required String fileName,
    File? file,
    Uint8List? fileBytes,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final uploadTask = _startSubmissionUploadTask(
      assignmentId: assignmentId,
      studentId: studentId,
      fileName: fileName,
      file: file,
      fileBytes: fileBytes,
      contentType: contentType,
    );

    final subscription =
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (snapshot.totalBytes > 0 && onProgress != null) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress.clamp(0.0, 1.0));
      }
    });

    try {
      final completedSnapshot = await uploadTask;
      return await completedSnapshot.ref.getDownloadURL();
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<String> uploadInstructorAudioFeedback({
    required String assignmentId,
    required String submissionId,
    required String fileName,
    File? audioFile,
    Uint8List? audioBytes,
    void Function(double progress)? onProgress,
  }) async {
    final safeFileName =
        'audio_${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(' ', '_')}';
    final storagePath =
        'assignments/$assignmentId/feedback_audio/$submissionId/$safeFileName';
    final ref = _storage.ref().child(storagePath);

    final metadata = SettableMetadata(
      contentType: 'audio/mp4',
      customMetadata: {
        'assignmentId': assignmentId,
        'submissionId': submissionId,
      },
    );

    UploadTask uploadTask;
    if (audioFile != null) {
      uploadTask = ref.putFile(audioFile, metadata);
    } else if (audioBytes != null) {
      uploadTask = ref.putData(audioBytes, metadata);
    } else {
      throw ArgumentError(
        'Ses dosyası (audioFile veya audioBytes) belirtilmelidir.',
      );
    }

    final subscription =
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (snapshot.totalBytes > 0 && onProgress != null) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress.clamp(0.0, 1.0));
      }
    });

    try {
      final completedSnapshot = await uploadTask;
      return await completedSnapshot.ref.getDownloadURL();
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> deleteFileByUrl(String fileUrl) async {
    final ref = _storage.refFromURL(fileUrl);
    await ref.delete();
  }

  String _inferContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'zip':
        return 'application/zip';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
