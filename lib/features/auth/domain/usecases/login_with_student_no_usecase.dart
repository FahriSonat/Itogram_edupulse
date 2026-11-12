import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Öğrenci numarası + şifre ile giriş yapar; başarılıysa rol bilgisini de
/// içeren [UserEntity] döner.
class LoginWithStudentNoUseCase {
  const LoginWithStudentNoUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call({
    required String studentNo,
    required String password,
  }) async {
    if (studentNo.trim().isEmpty || password.isEmpty) {
      return const Left(AuthFailure('Öğrenci numarası ve şifre zorunludur.'));
    }
    try {
      final user = await _repository.loginWithStudentNo(studentNo.trim(), password);
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
