import '../entities/forum_question_entity.dart';
import '../entities/forum_answer_entity.dart';

abstract class ForumRepository {
  Stream<List<ForumQuestionEntity>> watchForumQuestions({String? courseTag, String? topicTag});
  
  Future<void> askQuestionWithPhoto(ForumQuestionEntity question);
  
  Stream<List<ForumAnswerEntity>> watchForumAnswers(String questionId);
  
  Future<void> postForumAnswer(String questionId, ForumAnswerEntity answer);
  
  Future<void> markAnswerAsResolved(String questionId, String answerId);
}