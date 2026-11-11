import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Uygulama açılışında aktif oturumu kontrol eder. Oturum yoksa `Right(null)`.
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity?>> call() async {
    try {
      return Right(await _repository.getCurrentUser());
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
