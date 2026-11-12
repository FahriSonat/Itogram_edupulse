// Kural 5 Testi (Mutlak Rol Güvenliği) — Geliştirici 6
// Test edilen kod:
//   lib/core/router/role_guard.dart          (Geliştirici 1 — Yönlendirme Kalkanı)
//   lib/core/widgets/role_visibility_guard.dart (Geliştirici 2 — Arayüz Blokajı)
//
// Öğrenci rolündeki bir hesap:
//   1) not girişi ve yoklama başlatma bileşenlerini göremez,
//   2) deep link / URL manipülasyonuyla eğitmene özel sayfaya giremez.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/router/app_router.dart';
import 'package:itogram_edupulse/core/router/go_router_refresh_stream.dart';
import 'package:itogram_edupulse/core/router/role_guard.dart';
import 'package:itogram_edupulse/core/router/route_names.dart';
import 'package:itogram_edupulse/core/theme/app_theme.dart';
import 'package:itogram_edupulse/core/widgets/role_visibility_guard.dart';
import 'package:itogram_edupulse/features/announcements/presentation/pages/home_announcements_page.dart';
import 'package:itogram_edupulse/features/assignments/presentation/pages/assignment_control_page.dart';
import 'package:itogram_edupulse/features/assignments/presentation/pages/submission_grading_detail_page.dart';
import 'package:itogram_edupulse/features/attendance/presentation/pages/absence_control_page.dart';
import 'package:itogram_edupulse/features/attendance/presentation/pages/live_attendance_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/login_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/register_page.dart';
import 'package:itogram_edupulse/features/forum/presentation/pages/forum_page.dart';
import 'package:itogram_edupulse/features/forum/presentation/pages/forum_question_detail_page.dart';
import 'package:itogram_edupulse/features/grades/presentation/pages/grade_info_page.dart';
import 'package:itogram_edupulse/features/schedule/presentation/pages/weekly_schedule_page.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/page_harness.dart';

/// Fahri'nin AppRouter'ındaki rota ağacının sade kopyası: her sayfa kendi
/// yolunu yazar, böylece hangi ekranda olduğumuzu metinden okuyabiliriz.
GoRouter _buildRouter(AuthCubit cubit) {
  Widget page(String label) => Scaffold(body: Text('PAGE:$label'));
  final guard = RoleGuard(cubit);
  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: GoRouterRefreshStream(cubit.stream),
    redirect: guard.redirect,
    routes: <RouteBase>[
      GoRoute(path: RouteNames.splash, builder: (_, _) => page('splash')),
      GoRoute(path: RouteNames.login, builder: (_, _) => page('login')),
      GoRoute(path: RouteNames.register, builder: (_, _) => page('register')),
      GoRoute(path: RouteNames.forgotPassword, builder: (_, _) => page('forgot')),
      GoRoute(path: RouteNames.home, builder: (_, _) => page('home')),
      GoRoute(path: RouteNames.grades, builder: (_, _) => page('grades')),
      GoRoute(
        path: RouteNames.assignments,
        builder: (_, _) => page('assignments'),
        routes: <RouteBase>[
          GoRoute(
            path: 'grading/:${RouteNames.submissionGradingParam}',
            builder: (_, s) => page('grading:${s.pathParameters[RouteNames.submissionGradingParam]}'),
          ),
        ],
      ),
    ],
  );
}

void main() {
  late FakeAuthRepository repository;
  late AuthCubit cubit;
  late GoRouter router;

  setUp(() {
    repository = FakeAuthRepository();
    cubit = buildAuthCubit(repository);
    router = _buildRouter(cubit);
  });

  tearDown(() async {
    router.dispose();
    await cubit.close();
  });

  Future<void> pumpRouter(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Future<void> go(WidgetTester tester, String location) async {
    router.go(location);
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester, UserRole role) async {
    repository.loginResult = role == UserRole.instructor ? testInstructor : testStudent;
    await cubit.login(studentNo: '20261234', password: 'Sifre123!');
    await tester.pumpAndSettle();
  }

  group('RoleGuard — Yönlendirme Kalkanı (Kural 5)', () {
    testWidgets('oturum kontrolü sürerken (AuthInitial) Splash ekranında bekler', (tester) async {
      await pumpRouter(tester);
      expect(find.text('PAGE:splash'), findsOneWidget);

      await go(tester, RouteNames.grades);
      expect(find.text('PAGE:splash'), findsOneWidget, reason: 'Oturum bilinmeden korumalı sayfa açılmamalı');
    });

    testWidgets('oturum yoksa korumalı sayfalar /login\'e yönlenir', (tester) async {
      await pumpRouter(tester);
      await cubit.checkAuthStatus(); // currentUser == null → Unauthenticated
      await tester.pumpAndSettle();
      expect(find.text('PAGE:login'), findsOneWidget);

      await go(tester, RouteNames.home);
      expect(find.text('PAGE:login'), findsOneWidget);

      await go(tester, RouteNames.submissionGradingPath('s-1'));
      expect(find.text('PAGE:login'), findsOneWidget);
    });

    testWidgets('oturum yokken kayıt ve şifremi unuttum ekranları açılabilir', (tester) async {
      await pumpRouter(tester);
      await cubit.checkAuthStatus();
      await tester.pumpAndSettle();

      await go(tester, RouteNames.register);
      expect(find.text('PAGE:register'), findsOneWidget);
      await go(tester, RouteNames.forgotPassword);
      expect(find.text('PAGE:forgot'), findsOneWidget);
    });

    testWidgets('ÖĞRENCİ deep link ile notlandırma sayfasına giremez → /home', (tester) async {
      await pumpRouter(tester);
      await signIn(tester, UserRole.student);
      expect(find.text('PAGE:home'), findsOneWidget);

      await go(tester, RouteNames.submissionGradingPath('s-42'));
      expect(find.text('PAGE:grading:s-42'), findsNothing);
      expect(find.text('PAGE:home'), findsOneWidget);
    });

    testWidgets('ÖĞRENCİ normal öğrenci sayfalarına girebilir', (tester) async {
      await pumpRouter(tester);
      await signIn(tester, UserRole.student);

      await go(tester, RouteNames.assignments);
      expect(find.text('PAGE:assignments'), findsOneWidget);
      await go(tester, RouteNames.grades);
      expect(find.text('PAGE:grades'), findsOneWidget);
    });

    testWidgets('EĞİTMEN notlandırma sayfasına girebilir', (tester) async {
      await pumpRouter(tester);
      await signIn(tester, UserRole.instructor);

      await go(tester, RouteNames.submissionGradingPath('s-42'));
      expect(find.text('PAGE:grading:s-42'), findsOneWidget);
    });

    testWidgets('giriş yapmış kullanıcı login ekranına dönemez → /home', (tester) async {
      await pumpRouter(tester);
      await signIn(tester, UserRole.student);

      await go(tester, RouteNames.login);
      expect(find.text('PAGE:home'), findsOneWidget);
    });

    testWidgets('çıkış yapınca korumalı sayfadan /login\'e atılır', (tester) async {
      await pumpRouter(tester);
      await signIn(tester, UserRole.instructor);
      await go(tester, RouteNames.grades);
      expect(find.text('PAGE:grades'), findsOneWidget);

      await cubit.logout();
      await tester.pumpAndSettle();
      expect(find.text('PAGE:login'), findsOneWidget);
    });

    test('isInstructorOnly yalnızca notlandırma yolunu ve alt yollarını kapsar', () {
      expect(RoleGuard.isInstructorOnly(RouteNames.submissionGradingBase), isTrue);
      expect(RoleGuard.isInstructorOnly(RouteNames.submissionGradingPath('abc')), isTrue);
      expect(RoleGuard.isInstructorOnly(RouteNames.assignments), isFalse);
      expect(RoleGuard.isInstructorOnly(RouteNames.grades), isFalse);
      // Önek benzerliği yetki açığı yaratmamalı.
      expect(RoleGuard.isInstructorOnly('/assignments/gradingX'), isFalse);
    });
  });

  group('RoleVisibilityGuard — Arayüz Blokajı (Kural 5)', () {
    Widget instructorControls(UserRole role) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                RoleVisibilityGuard.onlyInstructor(
                  currentRole: role,
                  child: ElevatedButton(onPressed: () {}, child: const Text('Not Gir')),
                ),
                RoleVisibilityGuard.onlyInstructor(
                  currentRole: role,
                  child: ElevatedButton(onPressed: () {}, child: const Text('Yoklamayı Başlat')),
                ),
                RoleVisibilityGuard.onlyInstructor(
                  currentRole: role,
                  child: ElevatedButton(onPressed: () {}, child: const Text('Yeni Ödev Aç')),
                ),
                RoleVisibilityGuard.onlyStudent(
                  currentRole: role,
                  child: ElevatedButton(onPressed: () {}, child: const Text('PIN Gir')),
                ),
              ],
            ),
          ),
        );

    testWidgets('öğrenci not girişi, yoklama başlatma ve ödev açma butonlarını göremez', (tester) async {
      await tester.pumpWidget(instructorControls(UserRole.student));

      expect(find.text('Not Gir'), findsNothing);
      expect(find.text('Yoklamayı Başlat'), findsNothing);
      expect(find.text('Yeni Ödev Aç'), findsNothing);
      expect(find.text('PIN Gir'), findsOneWidget);
      // Butonlar gizlenmiyor, ağaçtan tamamen çıkarılıyor.
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('eğitmen yönetim butonlarını görür, öğrenci PIN girişini görmez', (tester) async {
      await tester.pumpWidget(instructorControls(UserRole.instructor));

      expect(find.text('Not Gir'), findsOneWidget);
      expect(find.text('Yoklamayı Başlat'), findsOneWidget);
      expect(find.text('Yeni Ödev Aç'), findsOneWidget);
      expect(find.text('PIN Gir'), findsNothing);
    });
  });

  group('AppRouter — Gerçek Sayfa Rotaları ve Shell Entegrasyonu', () {
    late TestBackend backend;

    setUp(() async {
      backend = TestBackend();
      await backend.register();
    });

    testWidgets('tüm rotalar gerçek sayfaları açar, parametreleri aktarır ve çıkış yapar', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final appRouter = AppRouter.buildRouter(authCubit: cubit);
      addTearDown(appRouter.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );
      await settle(tester);

      // Oturumsuz -> SplashPage checkAuthStatus tetikler -> LoginPage
      expect(find.byType(LoginPage), findsOneWidget);

      appRouter.go(RouteNames.register);
      await settle(tester);
      expect(find.byType(RegisterPage), findsOneWidget);

      appRouter.go(RouteNames.forgotPassword);
      await settle(tester);
      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      // Eğitmen girişi -> /home (HomeAnnouncementsPage) ve EĞİTMEN YÖNETİM PANELİ rozeti
      repository.loginResult = testInstructor;
      await cubit.login(studentNo: '20261234', password: 'Sifre123!');
      await settle(tester);
      expect(find.byType(HomeAnnouncementsPage), findsOneWidget);
      expect(find.text(AppStrings.instructorPortal), findsOneWidget);

      // Diğer tüm ana ve alt rotalar
      appRouter.go(RouteNames.schedule);
      await settle(tester);
      expect(find.byType(WeeklySchedulePage), findsOneWidget);

      appRouter.go(RouteNames.liveAttendance);
      await settle(tester);
      expect(find.byType(LiveAttendancePage), findsOneWidget);

      appRouter.go(RouteNames.assignments);
      await settle(tester);
      expect(find.byType(AssignmentControlPage), findsOneWidget);

      appRouter.go(
        RouteNames.submissionGradingPath('sub-99', assignmentId: 'asg-42'),
      );
      await settle(tester);
      final gradingPage = tester.widget<SubmissionGradingDetailPage>(
        find.byType(SubmissionGradingDetailPage),
      );
      expect(gradingPage.submissionId, 'sub-99');
      expect(gradingPage.assignmentId, 'asg-42');

      appRouter.go(RouteNames.absenceControl);
      await settle(tester);
      expect(find.byType(AbsenceControlPage), findsOneWidget);

      appRouter.go(RouteNames.grades);
      await settle(tester);
      expect(find.byType(GradeInfoPage), findsOneWidget);

      appRouter.go(RouteNames.forum);
      await settle(tester);
      expect(find.byType(ForumPage), findsOneWidget);

      appRouter.go(RouteNames.forumQuestionPath('q-77'));
      await settle(tester);
      final forumDetailPage = tester.widget<ForumQuestionDetailPage>(
        find.byType(ForumQuestionDetailPage),
      );
      expect(forumDetailPage.questionId, 'q-77');

      // Drawer üzerinden Çıkış Yap -> /login
      await tester.tap(
        find.byTooltip(const DefaultMaterialLocalizations().openAppDrawerTooltip),
      );
      await settle(tester);
      expect(find.text(testInstructor.fullName), findsOneWidget);
      await tester.tap(find.text(AppStrings.navLogout));
      await settle(tester);
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
