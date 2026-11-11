import '../enums/user_role.dart';
import 'route_names.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Kural 5 (Yönlendirme Kalkanı): GoRouter `redirect` içinde çalışır.
///  - Oturum yoksa -> /login
///  - Oturum varken auth ekranlarına -> /home
///  - Öğrenci, eğitmene özel rotaya (deep link dahil) -> /home
class RoleGuard {
  RoleGuard(this._authCubit);

  final AuthCubit _authCubit;

  /// Oturum gerektirmeyen ekranlar.
  static const Set<String> _publicRoutes = <String>{
    RouteNames.login,
    RouteNames.register,
    RouteNames.forgotPassword,
  };

  /// Sadece eğitmenin girebileceği yol önekleri.
  static const List<String> _instructorOnlyPrefixes = <String>[
    RouteNames.submissionGradingBase,
  ];

  static bool isInstructorOnly(String path) => _instructorOnlyPrefixes
      .any((String prefix) => path == prefix || path.startsWith('$prefix/'));

  String? redirect(BuildContext context, GoRouterState state) {
    final String path = state.uri.path;
    final AuthState authState = _authCubit.state;
    final bool onSplash = path == RouteNames.splash;
    final bool onPublic = _publicRoutes.contains(path);

    // Oturum kontrolü sürüyor: login ekranında AuthLoading'de zıplama yapma.
    if (authState is AuthInitial) {
      return onSplash ? null : RouteNames.splash;
    }
    if (authState is AuthLoading) {
      return null;
    }

    // Giriş yapılmış.
    if (authState is Authenticated) {
      if (onSplash || onPublic) return RouteNames.home;

      final bool isStudent = authState.user.role == UserRole.student;
      if (isStudent && isInstructorOnly(path)) return RouteNames.home;
      return null;
    }

    // Unauthenticated / PasswordResetSent / AuthError -> oturum yok.
    if (onPublic) return null;
    return RouteNames.login;
  }
}
