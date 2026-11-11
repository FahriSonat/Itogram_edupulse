import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/forum_answer_entity.dart';
import '../repositories/forum_repository.dart';

class PostForumAnswerUseCase {
  const PostForumAnswerUseCase(this._repository);

  final ForumRepository _repository;

  Future<ForumAnswerEntity> call({required UserEntity actor, required String questionId, required String answerText}) {
    final text = answerText.trim();
    if (text.isEmpty) throw const ValidationFailure('Cevap boş olamaz.');
    return _repository.postAnswer(responder: actor, questionId: questionId, answerText: text);
  }
}
