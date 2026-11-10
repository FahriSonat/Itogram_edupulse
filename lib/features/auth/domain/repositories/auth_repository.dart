import '../entities/user_entity.dart';
import '../../../../core/enums/user_role.dart';

abstract class AuthRepository {
  Future<UserEntity> loginWithStudentNo(String studentNo, String password);
  
  Future<UserEntity> registerUser({
    required String studentNo,
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  });
  
  Future<void> sendPasswordResetEmail(String email);
  
  Future<UserEntity?> getCurrentUser();
  
  Future<void> logout();
}