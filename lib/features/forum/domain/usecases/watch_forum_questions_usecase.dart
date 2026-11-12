import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/forum_answer_entity.dart';
import '../entities/forum_question_entity.dart';
import '../repositories/forum_repository.dart';

/// Ders / konu etiketine göre soruları ve bir sorunun yanıtlarını canlı izler.
class WatchForumQuestionsUseCase {
  const WatchForumQuestionsUseCase(this._repository);

  final ForumRepository _repository;

  Stream<Either<Failure, List<ForumQuestionEntity>>> call({String? courseTag, String? topicTag}) =>
      guardStream(_repository.watchForumQuestions(courseTag: courseTag, topicTag: topicTag));

  Stream<Either<Failure, List<ForumAnswerEntity>>> answers(String questionId) =>
      guardStream(_repository.watchForumAnswers(questionId));
}
