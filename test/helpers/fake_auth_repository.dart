import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/features/auth/domain/entities/user_entity.dart';
import 'package:itogram_edupulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:itogram_edupulse/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:itogram_edupulse/features/auth/domain/usecases/login_with_student_no_usecase.dart';
import 'package:itogram_edupulse/features/auth/domain/usecases/logout_usecase.dart';
import 'package:itogram_edupulse/features/auth/domain/usecases/register_user_usecase.dart';
import 'package:itogram_edupulse/features/auth/domain/usecases/send_password_reset_mail_usecase.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_cubit.dart';

const UserEntity testStudent = UserEntity(
  uid: 'uid-student',
  studentOrStaffNo: '20261234',
  fullName: 'Merve Kedersiz',
  email: 'merve@edupulse.edu.tr',
  role: UserRole.student,
);

const UserEntity testInstructor = UserEntity(
  uid: 'uid-instructor',
  studentOrStaffNo: 'S-001',
  fullName: 'Fahri Hoca',
  email: 'fahri@edupulse.edu.tr',
  role: UserRole.instructor,
);

/// Firebase'e bağlanmayan, davranışı test içinden ayarlanabilen AuthRepository.
class FakeAuthRepository implements AuthRepository {
  /// getCurrentUser() sonucu (oturum açık kullanıcı).
  UserEntity? currentUser;

  /// loginWithStudentNo() başarılıysa dönecek kullanıcı.
  UserEntity loginResult = testStudent;

  /// null değilse ilgili çağrı bu hatayı fırlatır.
  Object? error;

  final List<String> calls = <String>[];
  Map<String, Object?>? lastRegister;

  void _maybeThrow() {
    final e = error;
    if (e != null) throw e;
  }

  @override
  Future<UserEntity> loginWithStudentNo(String studentNo, String password) async {
    calls.add('login:$studentNo');
    _maybeThrow();
    currentUser = loginResult;
    return loginResult;
  }

  @override
  Future<UserEntity> registerUser({
    required String studentNo,
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    calls.add('register:$studentNo');
    lastRegister = <String, Object?>{
      'studentNo': studentNo,
      'fullName': fullName,
      'email': email,
      'role': role,
    };
    _maybeThrow();
    final user = UserEntity(uid: 'uid-new', studentOrStaffNo: studentNo, fullName: fullName, email: email, role: role);
    currentUser = user;
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    calls.add('reset:$email');
    _maybeThrow();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    calls.add('current');
    _maybeThrow();
    return currentUser;
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
    _maybeThrow();
    currentUser = null;
  }
}

AuthCubit buildAuthCubit(AuthRepository repository) => AuthCubit(
      loginWithStudentNoUseCase: LoginWithStudentNoUseCase(repository),
      registerUserUseCase: RegisterUserUseCase(repository),
      sendPasswordResetMailUseCase: SendPasswordResetMailUseCase(repository),
      getCurrentUserUseCase: GetCurrentUserUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
    );
