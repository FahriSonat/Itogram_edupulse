import '../../../../core/network/network_info.dart';
import '../../domain/entities/forum_answer_entity.dart';
import '../../domain/entities/forum_question_entity.dart';
import '../../domain/repositories/forum_repository.dart';
import '../datasources/forum_remote_datasource.dart';
import '../models/forum_answer_model.dart';
import '../models/forum_question_model.dart';

class ForumRepositoryImpl implements ForumRepository {
  final ForumRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ForumRepositoryImpl({
    ForumRemoteDataSource? remoteDataSource,
    NetworkInfo? networkInfo,
  })  : _remoteDataSource = remoteDataSource ?? ForumRemoteDataSourceImpl(),
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  @override
  Stream<List<ForumQuestionEntity>> watchForumQuestions({
    String? courseTag,
    String? topicTag,
  }) {
    return _remoteDataSource.watchForumQuestions(
      courseTag: courseTag,
      topicTag: topicTag,
    );
  }

  @override
  Future<void> askQuestionWithPhoto(ForumQuestionEntity question) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final model = question is ForumQuestionModel
        ? question
        : ForumQuestionModel(
            questionId: question.questionId,
            authorUid: question.authorUid,
            authorName: question.authorName,
            courseTag: question.courseTag,
            topicTag: question.topicTag,
            questionText: question.questionText,
            imageUrl: question.imageUrl,
            isResolved: question.isResolved,
          );

    await _remoteDataSource.askQuestionWithPhoto(model);
  }

  @override
  Stream<List<ForumAnswerEntity>> watchForumAnswers(String questionId) {
    return _remoteDataSource.watchForumAnswers(questionId);
  }

  @override
  Future<void> postForumAnswer(
    String questionId,
    ForumAnswerEntity answer,
  ) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final model = answer is ForumAnswerModel
        ? answer
        : ForumAnswerModel(
            answerId: answer.answerId,
            responderName: answer.responderName,
            responderRole: answer.responderRole,
            answerText: answer.answerText,
            isInstructorApproved: answer.isInstructorApproved,
          );

    await _remoteDataSource.postForumAnswer(questionId, model);
  }

  @override
  Future<void> markAnswerAsResolved(
    String questionId,
    String answerId,
  ) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    await _remoteDataSource.markAnswerAsResolved(questionId, answerId);
  }
}
