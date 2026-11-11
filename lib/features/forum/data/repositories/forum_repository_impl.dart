import '../../../../core/error/failures.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/forum_answer_entity.dart';
import '../../domain/entities/forum_question_entity.dart';
import '../../domain/repositories/forum_repository.dart';
import '../datasources/forum_remote_datasource.dart';
import '../models/forum_answer_model.dart';
import '../models/forum_question_model.dart';

class ForumRepositoryImpl implements ForumRepository {
  ForumRepositoryImpl({required this.remote, required this.notifications});

  final ForumRemoteDataSource remote;
  final NotificationService notifications;

  @override
  Stream<List<ForumQuestionEntity>> watchQuestions() => remote.watchQuestions();

  @override
  Stream<List<ForumAnswerEntity>> watchAnswers() => remote.watchAnswers();

  @override
  Future<ForumQuestionEntity> askQuestion({
    required UserEntity author,
    required String courseTag,
    required String topicTag,
    required String questionText,
    String? photoName,
  }) async {
    try {
      final model = ForumQuestionModel(
        id: remote.newId('q'),
        authorUid: author.uid,
        authorName: author.fullName,
        courseTag: courseTag,
        topicTag: topicTag,
        questionText: questionText,
        photoName: photoName,
        createdAt: DateTime.now(),
      );
      await remote.saveQuestion(model);
      return model;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  Future<ForumAnswerEntity> postAnswer({
    required UserEntity responder,
    required String questionId,
    required String answerText,
  }) async {
    try {
      final question = remote.getQuestion(questionId);
      if (question == null) throw const NotFoundFailure('Soru bulunamadı.');
      final model = ForumAnswerModel(
        id: remote.newId('ans'),
        questionId: questionId,
        responderUid: responder.uid,
        responderName: responder.fullName,
        responderRole: responder.role,
        answerText: answerText,
        createdAt: DateTime.now(),
      );
      await remote.saveAnswers([model]);
      if (question.authorUid != responder.uid) {
        await notifications.send(
          title: 'Sorunuza yeni cevap',
          body: '${responder.fullName}: $answerText',
          kind: NotificationKind.forum,
          targetUid: question.authorUid,
        );
      }
      return model;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  Future<void> markAnswerAsResolved({required String questionId, required String answerId}) async {
    try {
      final question = remote.getQuestion(questionId);
      if (question == null) throw const NotFoundFailure('Soru bulunamadı.');
      final answers = remote.getAnswers(questionId);
      if (!answers.any((a) => a.id == answerId)) throw const NotFoundFailure('Cevap bulunamadı.');

      await remote.saveAnswers([
        for (final a in answers) ForumAnswerModel.fromEntity(a.copyWith(isApproved: a.id == answerId)),
      ]);
      await remote.saveQuestion(
        ForumQuestionModel.fromEntity(question.copyWith(isResolved: true, resolvedAnswerId: answerId)),
      );
      await notifications.send(
        title: 'Sorunuz çözüldü',
        body: '"${question.questionText}" sorunuz için bir cevap eğitmen tarafından onaylandı.',
        kind: NotificationKind.forum,
        targetUid: question.authorUid,
      );
    } catch (e) {
      throw Failure.from(e);
    }
  }
}
