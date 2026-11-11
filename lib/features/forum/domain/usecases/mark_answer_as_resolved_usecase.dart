import 'package:dartz/dartz.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../repositories/forum_repository.dart';

/// Yalnızca Eğitmen yetkisiyle doğru cevabı "Çözüldü" olarak sabitler (Kural 5).
class MarkAnswerAsResolvedUseCase {
  const MarkAnswerAsResolvedUseCase(this._repository);

  final ForumRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String questionId,
    required String answerId,
    required UserRole role,
  }) async {
    if (role != UserRole.instructor) {
      return const Left(PermissionDeniedFailure('Yalnızca eğitmen cevabı onaylayabilir.'));
    }
    return guardFailure(() async {
      await _repository.markAnswerAsResolved(questionId, answerId);
      return unit;
    });
  }
}
