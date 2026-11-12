import 'package:dartz/dartz.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Öğrenci no, ad-soyad, e-posta, şifre (2 kez) ve seçilen [UserRole] ile
/// yeni hesap oluşturur.
class RegisterUserUseCase {
  const RegisterUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call({
    required String studentNo,
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required UserRole role,
  }) async {
    if (password != confirmPassword) {
      return const Left(AuthFailure('Şifreler eşleşmiyor.'));
    }
    try {
      final user = await _repository.registerUser(
        studentNo: studentNo.trim(),
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
        role: role,
      );
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
