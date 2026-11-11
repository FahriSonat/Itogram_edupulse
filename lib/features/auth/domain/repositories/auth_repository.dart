import '../../../../core/enums/user_role.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// [identifier]: öğrenci/sicil numarası veya kurumsal e-posta.
  Future<UserEntity> login({required String identifier, required String password});

  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String schoolNo,
    required String password,
    required UserRole role,
  });

  Future<void> logout();

  /// Kayıtlı oturum varsa kullanıcıyı döndürür.
  Future<UserEntity?> getCurrentUser();

  Future<void> sendPasswordResetEmail(String email);

  /// Kayıtlı tüm öğrenciler (yoklama listesi, not girişi için).
  Future<List<UserEntity>> getStudents();

  bool hasSeenOnboarding();

  Future<void> markOnboardingSeen();
}
