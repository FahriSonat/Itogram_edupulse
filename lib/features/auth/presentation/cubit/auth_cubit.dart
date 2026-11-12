import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/user_role.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_with_student_no_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_user_usecase.dart';
import '../../domain/usecases/send_password_reset_mail_usecase.dart';
import 'auth_state.dart';

/// Oturum durumunu tüm uygulamaya yayar. GoRouter (RoleGuard) ve
/// MultiBlocProvider aynı örneği kullandığı için DI'da LazySingleton'dır.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this.loginWithStudentNoUseCase,
    required this.registerUserUseCase,
    required this.sendPasswordResetMailUseCase,
    required this.getCurrentUserUseCase,
    required this.logoutUseCase,
  }) : super(const AuthInitial());

  final LoginWithStudentNoUseCase loginWithStudentNoUseCase;
  final RegisterUserUseCase registerUserUseCase;
  final SendPasswordResetMailUseCase sendPasswordResetMailUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final LogoutUseCase logoutUseCase;

  /// Uygulama açılışında (Splash) aktif oturumu kontrol eder.
  Future<void> checkAuthStatus() async {
    final result = await getCurrentUserUseCase();
    result.fold(
      (_) => emit(const Unauthenticated()),
      (user) => emit(user == null ? const Unauthenticated() : Authenticated(user)),
    );
  }

  Future<void> login({required String studentNo, required String password}) async {
    emit(const AuthLoading());
    final result = await loginWithStudentNoUseCase(studentNo: studentNo, password: password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> register({
    required String studentNo,
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required UserRole role,
  }) async {
    emit(const AuthLoading());
    final result = await registerUserUseCase(
      studentNo: studentNo,
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      role: role,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    emit(const AuthLoading());
    final result = await sendPasswordResetMailUseCase(email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(PasswordResetSent(email.trim())),
    );
  }

  Future<void> logout() async {
    await logoutUseCase();
    emit(const Unauthenticated());
  }
}
