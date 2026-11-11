import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_with_student_no_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_user_usecase.dart';
import '../../domain/usecases/send_password_reset_mail_usecase.dart';
import 'auth_state.dart';

/// [AuthCubit] oturum yaşam döngüsünü yönetir: açılışta oturum geri yükleme,
/// giriş, kayıt, şifre sıfırlama ve çıkış.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this._getCurrentUser,
    required this._login,
    required this._register,
    required this._logout,
    required this._sendPasswordReset,
  }) : super(const AuthState());

  final GetCurrentUserUseCase _getCurrentUser;
  final LoginWithStudentNoUseCase _login;
  final RegisterUserUseCase _register;
  final LogoutUseCase _logout;
  final SendPasswordResetMailUseCase _sendPasswordReset;

  UserEntity? _lastUser;

  UserEntity? get currentUser => state.user;

  /// Oturumdaki kullanıcı. Çıkış animasyonu sırasında kapanmakta olan
  /// ekranlar yeniden çizilirse son kullanıcıyı döndürür (null hatası önlenir).
  UserEntity get requireUser {
    final user = state.user ?? _lastUser;
    if (user == null) throw StateError('Oturum açmış kullanıcı yok.');
    return user;
  }

  @override
  void onChange(Change<AuthState> change) {
    super.onChange(change);
    final user = change.nextState.user;
    if (user != null) _lastUser = user;
  }

  Future<void> restoreSession() async {
    try {
      final user = await _getCurrentUser();
      emit(user == null ? const AuthState.unauthenticated() : AuthState.authenticated(user));
    } catch (_) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> login({required String identifier, required String password, UserRole? expectedRole}) async {
    if (state.isSubmitting) return;
    emit(const AuthState(status: AuthStatus.submitting));
    try {
      final user = await _login(identifier: identifier, password: password, expectedRole: expectedRole);
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.unauthenticated(Failure.from(e).message));
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String schoolNo,
    required String password,
    required UserRole role,
  }) async {
    if (state.isSubmitting) return;
    emit(const AuthState(status: AuthStatus.submitting));
    try {
      final user = await _register(
        fullName: fullName,
        email: email,
        schoolNo: schoolNo,
        password: password,
        role: role,
      );
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.unauthenticated(Failure.from(e).message));
    }
  }

  /// Başarılıysa null, değilse hata mesajı döndürür.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _sendPasswordReset(email);
      return null;
    } catch (e) {
      return Failure.from(e).message;
    }
  }

  Future<void> logout() async {
    try {
      await _logout();
    } finally {
      emit(const AuthState.unauthenticated());
    }
  }
}
