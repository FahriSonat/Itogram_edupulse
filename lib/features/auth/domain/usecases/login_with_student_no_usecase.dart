import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Öğrenci / sicil numarası (veya kurumsal e-posta) ve şifre ile giriş.
///
/// [expectedRole] verilirse (giriş ekranındaki portal seçimi) hesabın rolü
/// eşleşmediğinde oturum açılmaz — öğrenci hesabıyla eğitmen paneline
/// girilemez (Kural 5).
class LoginWithStudentNoUseCase {
  const LoginWithStudentNoUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call({required String identifier, required String password, UserRole? expectedRole}) async {
    final idError = Validators.loginIdentifier(identifier);
    if (idError != null) throw ValidationFailure(idError);
    final passError = Validators.password(password);
    if (passError != null) throw ValidationFailure(passError);

    final user = await _repository.login(identifier: identifier.trim(), password: password);
    if (expectedRole != null && user.role != expectedRole) {
      await _repository.logout();
      throw AuthFailure(
        'Bu hesap ${user.role.displayName.toLowerCase()} hesabıdır. '
        'Lütfen "${user.role.isStudent ? 'Öğrenci / Kursiyer' : 'Eğitmen / Yönetici'}" portalını seçiniz.',
      );
    }
    return user;
  }
}
