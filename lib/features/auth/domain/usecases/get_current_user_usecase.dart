import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Uygulama açılışında kayıtlı oturumu geri yükler.
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity?> call() => _repository.getCurrentUser();
}
