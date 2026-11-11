import '../enums/user_role.dart';
import '../error/failures.dart';
import 'route_names.dart';

/// [RoleGuard] Kural 5'i (Mutlak Rol Güvenliği) iki katmanda uygular:
///
/// 1. **Rota:** Yalnızca eğitmenin açabileceği sayfalara öğrenci erişemez
///    ([canAccess]); router yetkisiz isteği "erişim yok" ekranına yönlendirir.
/// 2. **İş mantığı:** Eğitmene özel use case'ler [requireInstructor] ile
///    korunur; arayüz atlatılsa bile işlem reddedilir.
abstract final class RoleGuard {
  static const Set<String> instructorOnlyRoutes = {RouteNames.submissionGrading};

  static const Set<String> studentOnlyRoutes = <String>{};

  static bool canAccess(String? routeName, UserRole? role) {
    if (routeName == null) return true;
    if (instructorOnlyRoutes.contains(routeName)) return role == UserRole.instructor;
    if (studentOnlyRoutes.contains(routeName)) return role == UserRole.student;
    return true;
  }

  static void requireInstructor(UserRole? role) {
    if (role != UserRole.instructor) throw const UnauthorizedFailure();
  }

  static void requireStudent(UserRole? role) {
    if (role != UserRole.student) {
      throw const UnauthorizedFailure('Bu işlem yalnızca öğrenciler tarafından yapılabilir.');
    }
  }
}
