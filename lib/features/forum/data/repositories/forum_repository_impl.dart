import 'dart:io';
import 'dart:typed_data';
import '../../../../core/enums/user_role.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/forum_remote_datasource.dart';

class ForumRepositoryImpl {
  final ForumRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ForumRepositoryImpl({
    ForumRemoteDataSource? remoteDataSource,
    NetworkInfo? networkInfo,
  })  : _remoteDataSource = remoteDataSource ?? ForumRemoteDataSourceImpl(),
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  Stream<List<Map<String, dynamic>>> watchForumQuestions({
    String? courseId,
    bool? onlyResolved,
  }) {
    return _remoteDataSource.watchForumQuestions(
      courseId: courseId,
      onlyResolved: onlyResolved,
    );
  }

  Stream<List<Map<String, dynamic>>> watchQuestionAnswers(String questionId) {
    return _remoteDataSource.watchQuestionAnswers(questionId);
  }

  /// Öğrencinin çektiği soru fotoğrafını Firebase Storage'a yükler,
  /// soru ve etiketleri (`tags`) Firestore `forum_questions` koleksiyonuna yazar.
  Future<Map<String, dynamic>> askQuestionWithPhoto({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    required UserRole authorRole,
    String? courseId,
    String? courseName,
    List<String> tags = const [],
    File? photoFile,
    Uint8List? photoBytes,
    String? photoFileName,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    return _remoteDataSource.askQuestionWithPhoto(
      title: title,
      content: content,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      courseId: courseId,
      courseName: courseName,
      tags: tags,
      photoFile: photoFile,
      photoBytes: photoBytes,
      photoFileName: photoFileName,
    );
  }

  Future<Map<String, dynamic>> postForumAnswer({
    required String questionId,
    required String content,
    required String authorId,
    required String authorName,
    required UserRole authorRole,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    return _remoteDataSource.postForumAnswer(
      questionId: questionId,
      content: content,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
    );
  }

  /// Eğitmen bir yanıtı "Çözüldü" olarak işaretlediğinde Atomik Batch Write ile
  /// hem yanıtı `isInstructorApproved = true` hem de soruyu `isResolved = true` olarak günceller.
  Future<void> markAnswerAsResolved({
    required String questionId,
    required String answerId,
    bool isResolved = true,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    await _remoteDataSource.markAnswerAsResolved(
      questionId: questionId,
      answerId: answerId,
      isResolved: isResolved,
    );
  }
}
