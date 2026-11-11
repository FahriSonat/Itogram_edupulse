import '../entities/forum_answer_entity.dart';
import '../entities/forum_question_entity.dart';
import '../repositories/forum_repository.dart';

/// Forum soruları ve cevaplarını canlı dinler.
class WatchForumQuestionsUseCase {
  const WatchForumQuestionsUseCase(this._repository);

  final ForumRepository _repository;

  Stream<List<ForumQuestionEntity>> call() => _repository.watchQuestions();

  Stream<List<ForumAnswerEntity>> answers() => _repository.watchAnswers();
}
