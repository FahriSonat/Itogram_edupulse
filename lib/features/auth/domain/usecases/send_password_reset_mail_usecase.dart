import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Kayıtlı e-postaya Firebase şifre sıfırlama bağlantısı gönderir.
class SendPasswordResetMailUseCase {
  const SendPasswordResetMailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call(String email) async {
    if (email.trim().isEmpty) {
      return const Left(AuthFailure('E-posta adresi zorunludur.'));
    }
    try {
      await _repository.sendPasswordResetEmail(email.trim());
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
