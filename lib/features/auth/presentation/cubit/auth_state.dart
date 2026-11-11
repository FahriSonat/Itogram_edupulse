import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

enum AuthStatus {
  /// Kayıtlı oturum henüz kontrol edilmedi.
  unknown,
  unauthenticated,

  /// Giriş / kayıt isteği sürüyor.
  submitting,
  authenticated,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({this.status = AuthStatus.unknown, this.user, this.errorMessage});

  const AuthState.unauthenticated([String? error])
    : status = AuthStatus.unauthenticated,
      user = null,
      errorMessage = error;

  const AuthState.authenticated(UserEntity this.user) : status = AuthStatus.authenticated, errorMessage = null;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isSubmitting => status == AuthStatus.submitting;

  @override
  List<Object?> get props => [status, user, errorMessage];
}
