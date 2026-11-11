import '../../../../core/router/role_guard.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/forum_repository.dart';

/// Eğitmenin bir cevabı "çözüm" olarak onaylaması (Kural 5: yalnızca eğitmen).
class MarkAnswerAsResolvedUseCase {
  const MarkAnswerAsResolvedUseCase(this._repository);

  final ForumRepository _repository;

  Future<void> call({required UserEntity actor, required String questionId, required String answerId}) {
    RoleGuard.requireInstructor(actor.role);
    return _repository.markAnswerAsResolved(questionId: questionId, answerId: answerId);
  }
}
