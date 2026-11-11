import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Yeni öğrenci veya eğitmen hesabı oluşturur ve oturumu açar.
class RegisterUserUseCase {
  const RegisterUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call({
    required String fullName,
    required String email,
    required String schoolNo,
    required String password,
    required UserRole role,
  }) {
    final error =
        Validators.fullName(fullName) ??
        Validators.email(email) ??
        Validators.studentNo(schoolNo) ??
        Validators.password(password);
    if (error != null) throw ValidationFailure(error);
    return _repository.register(fullName: fullName, email: email, schoolNo: schoolNo, password: password, role: role);
  }
}
