import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/error/failures.dart';
import 'package:itogram_edupulse/core/router/role_guard.dart';
import 'package:itogram_edupulse/core/router/route_names.dart';

void main() {
  group('Kural 5 — Mutlak Rol Güvenliği', () {
    test('öğrenci eğitmene özel rotaya erişemez', () {
      expect(RoleGuard.canAccess(RouteNames.submissionGrading, UserRole.student), isFalse);
      expect(RoleGuard.canAccess(RouteNames.submissionGrading, null), isFalse);
    });

    test('eğitmen eğitmene özel rotaya erişebilir', () {
      expect(RoleGuard.canAccess(RouteNames.submissionGrading, UserRole.instructor), isTrue);
    });

    test('ortak rotalar her iki role açıktır', () {
      for (final route in [RouteNames.liveAttendance, RouteNames.absenceControl, RouteNames.forumQuestionDetail]) {
        expect(RoleGuard.canAccess(route, UserRole.student), isTrue, reason: route);
        expect(RoleGuard.canAccess(route, UserRole.instructor), isTrue, reason: route);
      }
    });

    test('requireInstructor öğrenci için UnauthorizedFailure fırlatır', () {
      expect(() => RoleGuard.requireInstructor(UserRole.student), throwsA(isA<UnauthorizedFailure>()));
      expect(() => RoleGuard.requireInstructor(null), throwsA(isA<UnauthorizedFailure>()));
      expect(() => RoleGuard.requireInstructor(UserRole.instructor), returnsNormally);
    });

    test('requireStudent eğitmen için UnauthorizedFailure fırlatır', () {
      expect(() => RoleGuard.requireStudent(UserRole.instructor), throwsA(isA<UnauthorizedFailure>()));
      expect(() => RoleGuard.requireStudent(UserRole.student), returnsNormally);
    });
  });
}
