import 'package:dartz/dartz.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/forum_answer_entity.dart';
import '../repositories/forum_repository.dart';

/// Soruya yanıt gönderir.
class PostForumAnswerUseCase {
  const PostForumAnswerUseCase(this._repository);

  final ForumRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String questionId,
    required String responderName,
    required UserRole responderRole,
    required String answerText,
  }) async {
    if (answerText.trim().isEmpty) {
      return const Left(ServerFailure('Yanıt boş olamaz.'));
    }
    return guardFailure(() async {
      await _repository.postForumAnswer(
        questionId,
        ForumAnswerEntity(
          answerId: '',
          responderName: responderName,
          responderRole: responderRole.name,
          answerText: answerText.trim(),
          isInstructorApproved: false,
        ),
      );
      return unit;
    });
  }
}
