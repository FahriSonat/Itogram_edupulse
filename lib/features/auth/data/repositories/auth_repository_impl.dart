import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.local});

  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  Future<UserEntity> login({required String identifier, required String password}) => _guard(() async {
    final user = await remote.login(identifier: identifier, password: password);
    await local.cacheUid(user.uid);
    return user;
  });

  @override
  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String schoolNo,
    required String password,
    required UserRole role,
  }) => _guard(() async {
    final user = await remote.register(
      fullName: fullName,
      email: email,
      schoolNo: schoolNo,
      password: password,
      role: role,
    );
    await local.cacheUid(user.uid);
    return user;
  });

  @override
  Future<void> logout() => _guard(local.clearSession);

  @override
  Future<UserEntity?> getCurrentUser() => _guard(() async {
    final uid = local.getCachedUid();
    if (uid == null) return null;
    final user = await remote.getUser(uid);
    if (user == null) await local.clearSession();
    return user;
  });

  @override
  Future<void> sendPasswordResetEmail(String email) => _guard(() => remote.sendPasswordResetEmail(email));

  @override
  Future<List<UserEntity>> getStudents() => _guard(() => remote.getUsersByRole(UserRole.student));

  @override
  bool hasSeenOnboarding() => local.hasSeenOnboarding();

  @override
  Future<void> markOnboardingSeen() => _guard(local.markOnboardingSeen);
}
