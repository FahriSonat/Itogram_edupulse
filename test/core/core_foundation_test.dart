// Geliştirici 1 (Fahri) — core katmanı: enum'lar, hata sınıfları, rota
// sabitleri, FlavorConfig ve GoRouterRefreshStream testleri.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/config/flavor_config.dart';
import 'package:itogram_edupulse/core/enums/announcement_type.dart';
import 'package:itogram_edupulse/core/enums/submission_status.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/error/exceptions.dart';
import 'package:itogram_edupulse/core/error/failures.dart';
import 'package:itogram_edupulse/core/router/go_router_refresh_stream.dart';
import 'package:itogram_edupulse/core/router/route_names.dart';

void main() {
  group('UserRole', () {
    test('toJson / fromJson tutarlıdır', () {
      for (final role in UserRole.values) {
        expect(UserRoleX.fromJson(role.toJson()), role);
      }
    });

    test('GÜVENLİK: bilinmeyen / boş rol en düşük yetkiye (student) düşer', () {
      expect(UserRoleX.fromJson('superadmin'), UserRole.student);
      expect(UserRoleX.fromJson('INSTRUCTOR'), UserRole.student, reason: 'büyük harf eşleşmemeli');
      expect(UserRoleX.fromJson(null), UserRole.student);
    });

    test('rol yardımcıları ve rozet metinleri', () {
      expect(UserRole.instructor.isInstructor, isTrue);
      expect(UserRole.student.isInstructor, isFalse);
      expect(UserRole.student.isStudent, isTrue);
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.student.badgeLabel, 'ÖĞRENCİ PORTALI');
      expect(UserRole.instructor.badgeLabel, 'EĞİTMEN YÖNETİM PANELİ');
    });
  });

  group('SubmissionStatus', () {
    test('Türkçe etiketler (Bekliyor / Teslim Edildi / Gecikti)', () {
      expect(SubmissionStatus.pending.label, 'Bekliyor');
      expect(SubmissionStatus.submitted.label, 'Teslim Edildi');
      expect(SubmissionStatus.late.label, 'Gecikti');
    });

    test('toJson / fromJson; bilinmeyen değer pending', () {
      for (final s in SubmissionStatus.values) {
        expect(SubmissionStatusX.fromJson(s.toJson()), s);
      }
      expect(SubmissionStatusX.fromJson('???'), SubmissionStatus.pending);
    });
  });

  group('AnnouncementType', () {
    test('toJson / fromJson; bilinmeyen değer general', () {
      for (final t in AnnouncementType.values) {
        expect(AnnouncementTypeX.fromJson(t.toJson()), t);
      }
      expect(AnnouncementTypeX.fromJson(null), AnnouncementType.general);
    });

    test('her türün boş olmayan bir etiketi vardır', () {
      for (final t in AnnouncementType.values) {
        expect(t.label, isNotEmpty);
      }
    });
  });

  group('Exceptions & Failures', () {
    test('varsayılan Türkçe mesajlar', () {
      expect(const ExpiredQrPinException().message, contains('süresi doldu'));
      expect(const UnauthorizedRoleException().message, contains('yetkiniz yok'));
      expect(const PermissionDeniedFailure().message, contains('yetkiniz yok'));
      expect(const ExpiredCodeFailure().message, contains('süresi doldu'));
    });

    test('istisnalar Exception tipindedir ve toString tip adını içerir', () {
      const e = ExpiredQrPinException('özel mesaj');
      expect(e, isA<Exception>());
      expect(e.toString(), 'ExpiredQrPinException: özel mesaj');
    });

    test('Failure sınıfları Equatable: aynı mesaj = eşit', () {
      expect(const ServerFailure('x'), const ServerFailure('x'));
      expect(const ServerFailure('x'), isNot(const ServerFailure('y')));
      expect(const AuthFailure().message, 'Giriş işlemi başarısız.');
    });
  });

  group('RouteNames', () {
    test('şartnamedeki tüm ekran yolları tanımlı', () {
      expect(<String>[
        RouteNames.splash,
        RouteNames.login,
        RouteNames.register,
        RouteNames.forgotPassword,
        RouteNames.home,
        RouteNames.schedule,
        RouteNames.liveAttendance,
        RouteNames.assignments,
        RouteNames.absenceControl,
        RouteNames.grades,
        RouteNames.forum,
      ], <String>[
        '/splash',
        '/login',
        '/register',
        '/forgot-password',
        '/home',
        '/schedule',
        '/live-attendance',
        '/assignments',
        '/absence-control',
        '/grades',
        '/forum',
      ]);
    });

    test('notlandırma detay yolu ödevlerin altındadır', () {
      expect(RouteNames.submissionGradingPath('abc'), '/assignments/grading/abc');
      expect(RouteNames.submissionGradingPath('abc'), startsWith(RouteNames.assignments));
    });
  });

  group('FlavorConfig', () {
    tearDown(() => FlavorConfig.initialize(Flavor.dev));

    test('varsayılan ortam dev: banner ve log açık, Crashlytics kapalı', () {
      FlavorConfig.initialize(FlavorConfig.fromEnvironment());
      expect(FlavorConfig.isDev, isTrue);
      expect(FlavorConfig.showBanner, isTrue);
      expect(FlavorConfig.enableLogging, isTrue);
      expect(FlavorConfig.enableCrashlytics, isFalse);
    });

    test('prod (Demo Day): banner ve log kapalı, Crashlytics açık', () {
      FlavorConfig.initialize(Flavor.prod);
      expect(FlavorConfig.isProd, isTrue);
      expect(FlavorConfig.name, 'prod');
      expect(FlavorConfig.showBanner, isFalse);
      expect(FlavorConfig.enableLogging, isFalse);
      expect(FlavorConfig.enableCrashlytics, isTrue);
    });
  });

  group('GoRouterRefreshStream', () {
    test('akıştaki her olayda dinleyicileri uyarır, dispose sonrası durur', () async {
      final controller = StreamController<int>();
      final refresh = GoRouterRefreshStream(controller.stream);
      var notified = 0;
      refresh.addListener(() => notified++);

      controller
        ..add(1)
        ..add(2);
      await Future<void>.delayed(Duration.zero);
      expect(notified, 2);

      refresh.dispose();
      expect(controller.hasListener, isFalse);
      await controller.close();
    });
  });
}
