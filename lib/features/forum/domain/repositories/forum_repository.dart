import '../../../auth/domain/entities/user_entity.dart';
import '../entities/forum_answer_entity.dart';
import '../entities/forum_question_entity.dart';

abstract class ForumRepository {
  Stream<List<ForumQuestionEntity>> watchQuestions();

  Stream<List<ForumAnswerEntity>> watchAnswers();

  Future<ForumQuestionEntity> askQuestion({
    required UserEntity author,
    required String courseTag,
    required String topicTag,
    required String questionText,
    String? photoName,
  });

  Future<ForumAnswerEntity> postAnswer({
    required UserEntity responder,
    required String questionId,
    required String answerText,
  });

  /// Cevabı çözüm olarak işaretler ve soruyu "Çözüldü" durumuna alır.
  Future<void> markAnswerAsResolved({required String questionId, required String answerId});
}
