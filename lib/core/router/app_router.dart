import '../di/injection_container.dart';

import 'package:itogram_edupulse/core/router/go_router_refresh_stream.dart';
import 'package:itogram_edupulse/core/router/role_guard.dart';
import 'package:itogram_edupulse/core/router/route_names.dart';
import 'package:itogram_edupulse/core/widgets/main_scaffold_shell.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// TODO(Dev6): Sayfalar gelince placeholder'ları gerçekleriyle değiştir:
// import 'package:edupulse/features/auth/presentation/pages/splash_page.dart';
// import 'package:edupulse/features/auth/presentation/pages/login_page.dart';
// import 'package:edupulse/features/auth/presentation/pages/register_page.dart';
// import 'package:edupulse/features/auth/presentation/pages/forgot_password_page.dart';
// import 'package:edupulse/features/announcements/presentation/pages/home_announcements_page.dart';
// import 'package:edupulse/features/schedule/presentation/pages/weekly_schedule_page.dart';
// import 'package:edupulse/features/attendance/presentation/pages/live_attendance_page.dart';
// import 'package:edupulse/features/attendance/presentation/pages/absence_control_page.dart';
// import 'package:edupulse/features/assignments/presentation/pages/assignment_control_page.dart';
// import 'package:edupulse/features/assignments/presentation/pages/submission_grading_detail_page.dart';
// import 'package:edupulse/features/grades/presentation/pages/grade_info_page.dart';
// import 'package:edupulse/features/forum/presentation/pages/forum_page.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  /// initDependencies() çalıştıktan sonra ilk erişimde oluşur (lazy static).
  static final GoRouter router = _build();

  static GoRouter _build() {
    final AuthCubit authCubit = sl<AuthCubit>();
    final RoleGuard guard = RoleGuard(authCubit);

    return GoRouter(
      navigatorKey: _rootKey,
      initialLocation: RouteNames.splash,
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: guard.redirect,
      routes: <RouteBase>[
        // ---- Shell dışı: Auth ekranları ----
        GoRoute(
          path: RouteNames.splash,
          name: RouteNames.splashName,
          builder: (BuildContext c, GoRouterState s) =>
              const _PlaceholderPage('Splash'), // SplashPage()
        ),
        GoRoute(
          path: RouteNames.login,
          name: RouteNames.loginName,
          builder: (BuildContext c, GoRouterState s) =>
              const _PlaceholderPage('Giriş Yap'), // LoginPage()
        ),
        GoRoute(
          path: RouteNames.register,
          name: RouteNames.registerName,
          builder: (BuildContext c, GoRouterState s) =>
              const _PlaceholderPage('Kayıt Ol'), // RegisterPage()
        ),
        GoRoute(
          path: RouteNames.forgotPassword,
          name: RouteNames.forgotPasswordName,
          builder: (BuildContext c, GoRouterState s) =>
              const _PlaceholderPage('Şifremi Unuttum'), // ForgotPasswordPage()
        ),

        // ---- Shell içi: Drawer + BottomNavigationBar ----
        ShellRoute(
          navigatorKey: _shellKey,
          builder: (BuildContext c, GoRouterState s, Widget child) =>
              MainScaffoldShell(child: child),
          routes: <RouteBase>[
            GoRoute(
              path: RouteNames.home,
              name: RouteNames.homeName,
              builder: (BuildContext c, GoRouterState s) =>
                  const _PlaceholderPage('Ana Sayfa'), // HomeAnnouncementsPage()
            ),
            GoRoute(
              path: RouteNames.schedule,
              name: RouteNames.scheduleName,
              builder: (BuildContext c, GoRouterState s) =>
                  const _PlaceholderPage('Ders Programı'), // WeeklySchedulePage()
            ),
            GoRoute(
              path: RouteNames.liveAttendance,
              name: RouteNames.liveAttendanceName,
              builder: (BuildContext c, GoRouterState s) =>
                  const _PlaceholderPage('Canlı Yoklama'), // LiveAttendancePage()
            ),
            GoRoute(
              path: RouteNames.assignments,
              name: RouteNames.assignmentsName,
              builder: (BuildContext c, GoRouterState s) =>
                  const _PlaceholderPage('Ödev Kontrol'), // AssignmentControlPage()
              routes: <RouteBase>[
                // Sadece eğitmen: RoleGuard bu yolu öğrenciye kapatır.
                GoRoute(
                  path: 'grading/:${RouteNames.submissionGradingParam}',
                  name: RouteNames.submissionGradingName,
                  builder: (BuildContext c, GoRouterState s) {
                    final String id =
                        s.pathParameters[RouteNames.submissionGradingParam] ??
                            '';
                    return _PlaceholderPage('Notlandırma: $id');
                    // SubmissionGradingDetailPage(submissionId: id)
                  },
                ),
              ],
            ),
            GoRoute(
              path: RouteNames.absenceControl,
              name: RouteNames.absenceControlName,
              builder: (BuildContext c, GoRouterState s) =>
                  const _PlaceholderPage('Devamsızlık Kontrol'), // AbsenceControlPage()
            ),
            GoRoute(
              path: RouteNames.grades,
              name: RouteNames.gradesName,
              builder: (BuildContext c, GoRouterState s) =>
                  const _PlaceholderPage('Not Bilgisi'), // GradeInfoPage()
            ),
            GoRoute(
              path: RouteNames.forum,
              name: RouteNames.forumName,
              builder: (BuildContext c, GoRouterState s) =>
                  const _PlaceholderPage('Kampüs Forumu'), // ForumPage()
            ),
          ],
        ),
      ],
    );
  }
}

/// Dev6'nın sayfaları gelene kadar geçici ekran.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title)));
  }
}
