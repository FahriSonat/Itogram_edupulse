import 'package:equatable/equatable.dart';

import '../../../../core/enums/user_role.dart';
import '../../domain/entities/user_entity.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  /// Giriş yapan kullanıcı eğitmen mi? (Kural 5 — arayüz kararları için)
  bool get isInstructor => false;

  @override
  List<Object?> get props => <Object?>[];
}

/// Oturum henüz kontrol edilmedi (Splash).
class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);

  final UserEntity user;

  @override
  bool get isInstructor => user.role == UserRole.instructor;

  @override
  List<Object?> get props => <Object?>[user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class PasswordResetSent extends AuthState {
  const PasswordResetSent(this.email);

  final String email;

  @override
  List<Object?> get props => <Object?>[email];
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
