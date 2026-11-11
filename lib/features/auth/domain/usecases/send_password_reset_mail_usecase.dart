import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetMailUseCase {
  const SendPasswordResetMailUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email) {
    final error = Validators.email(email);
    if (error != null) throw ValidationFailure(error);
    return _repository.sendPasswordResetEmail(email.trim());
  }
}
