import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/router/go_router_refresh_stream.dart';
import 'package:itogram_edupulse/core/router/role_guard.dart';
import 'package:itogram_edupulse/core/router/route_names.dart';
import 'package:itogram_edupulse/core/widgets/main_scaffold_shell.dart';
import 'package:itogram_edupulse/features/announcements/presentation/pages/home_announcements_page.dart';
import 'package:itogram_edupulse/features/assignments/presentation/pages/assignment_control_page.dart';
import 'package:itogram_edupulse/features/assignments/presentation/pages/submission_grading_detail_page.dart';
import 'package:itogram_edupulse/features/attendance/presentation/pages/absence_control_page.dart';
import 'package:itogram_edupulse/features/attendance/presentation/pages/live_attendance_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_state.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/login_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/register_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/splash_page.dart';
import 'package:itogram_edupulse/features/forum/presentation/pages/forum_page.dart';
import 'package:itogram_edupulse/features/forum/presentation/pages/forum_question_detail_page.dart';
import 'package:itogram_edupulse/features/grades/presentation/pages/grade_info_page.dart';
import 'package:itogram_edupulse/features/schedule/presentation/pages/weekly_schedule_page.dart';

import '../di/injection_container.dart';

class AppRouter {
  AppRouter._();

  /// initDependencies() çalıştıktan sonra ilk erişimde oluşur (lazy static).
  static final GoRouter router = buildRouter();

  /// Gerçek uygulama ve entegrasyon testleri için GoRouter örneği üretir.
  static GoRouter buildRouter({
    AuthCubit? authCubit,
    String initialLocation = RouteNames.splash,
  }) {
    final AuthCubit resolvedAuthCubit = authCubit ?? sl<AuthCubit>();
    final RoleGuard guard = RoleGuard(resolvedAuthCubit);
    final GlobalKey<NavigatorState> rootKey =
        GlobalKey<NavigatorState>(debugLabel: 'root');
    final GlobalKey<NavigatorState> shellKey =
        GlobalKey<NavigatorState>(debugLabel: 'shell');

    Widget withAuth(Widget child) => BlocProvider<AuthCubit>.value(
          value: resolvedAuthCubit,
          child: child,
        );

    return GoRouter(
      navigatorKey: rootKey,
      initialLocation: initialLocation,
      refreshListenable: GoRouterRefreshStream(resolvedAuthCubit.stream),
      redirect: guard.redirect,
      routes: <RouteBase>[
        // ---- Shell dışı: Auth ekranları ----
        GoRoute(
          path: RouteNames.splash,
          name: RouteNames.splashName,
          builder: (BuildContext c, GoRouterState s) =>
              withAuth(const SplashPage()),
        ),
        GoRoute(
          path: RouteNames.login,
          name: RouteNames.loginName,
          builder: (BuildContext c, GoRouterState s) =>
              withAuth(const LoginPage()),
        ),
        GoRoute(
          path: RouteNames.register,
          name: RouteNames.registerName,
          builder: (BuildContext c, GoRouterState s) =>
              withAuth(const RegisterPage()),
        ),
        GoRoute(
          path: RouteNames.forgotPassword,
          name: RouteNames.forgotPasswordName,
          builder: (BuildContext c, GoRouterState s) =>
              withAuth(const ForgotPasswordPage()),
        ),

        // ---- Shell içi: Drawer + BottomNavigationBar ----
        ShellRoute(
          navigatorKey: shellKey,
          builder: (BuildContext c, GoRouterState s, Widget child) {
            return withAuth(
              BlocBuilder<AuthCubit, AuthState>(
                bloc: resolvedAuthCubit,
                builder: (BuildContext context, AuthState state) {
                  final user = state is Authenticated ? state.user : null;
                  final emailOrNo = user == null
                      ? ''
                      : (user.studentOrStaffNo.isNotEmpty
                          ? user.studentOrStaffNo
                          : user.email);
                  return MainScaffoldShell(
                    currentRoute: s.uri.path,
                    userRole: user?.role ?? UserRole.student,
                    userName: (user != null && user.fullName.isNotEmpty)
                        ? user.fullName
                        : AppStrings.appName,
                    userEmailOrNo: emailOrNo,
                    onLogout: resolvedAuthCubit.logout,
                    child: child,
                  );
                },
              ),
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: RouteNames.home,
              name: RouteNames.homeName,
              builder: (BuildContext c, GoRouterState s) =>
                  const HomeAnnouncementsPage(),
            ),
            GoRoute(
              path: RouteNames.schedule,
              name: RouteNames.scheduleName,
              builder: (BuildContext c, GoRouterState s) =>
                  const WeeklySchedulePage(),
            ),
            GoRoute(
              path: RouteNames.liveAttendance,
              name: RouteNames.liveAttendanceName,
              builder: (BuildContext c, GoRouterState s) =>
                  const LiveAttendancePage(),
            ),
            GoRoute(
              path: RouteNames.assignments,
              name: RouteNames.assignmentsName,
              builder: (BuildContext c, GoRouterState s) =>
                  const AssignmentControlPage(),
              routes: <RouteBase>[
                // Sadece eğitmen: RoleGuard bu yolu öğrenciye kapatır.
                GoRoute(
                  path: 'grading/:${RouteNames.submissionGradingParam}',
                  name: RouteNames.submissionGradingName,
                  builder: (BuildContext c, GoRouterState s) {
                    final String submissionId =
                        s.pathParameters[RouteNames.submissionGradingParam] ??
                            '';
                    final String assignmentId = s.uri.queryParameters[RouteNames
                            .submissionGradingAssignmentQueryParam] ??
                        '';
                    return SubmissionGradingDetailPage(
                      submissionId: submissionId,
                      assignmentId: assignmentId,
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: RouteNames.absenceControl,
              name: RouteNames.absenceControlName,
              builder: (BuildContext c, GoRouterState s) =>
                  const AbsenceControlPage(),
            ),
            GoRoute(
              path: RouteNames.grades,
              name: RouteNames.gradesName,
              builder: (BuildContext c, GoRouterState s) =>
                  const GradeInfoPage(),
            ),
            GoRoute(
              path: RouteNames.forum,
              name: RouteNames.forumName,
              builder: (BuildContext c, GoRouterState s) => const ForumPage(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'question/:${RouteNames.forumQuestionParam}',
                  name: RouteNames.forumQuestionName,
                  builder: (BuildContext c, GoRouterState s) {
                    final String questionId =
                        s.pathParameters[RouteNames.forumQuestionParam] ?? '';
                    return ForumQuestionDetailPage(questionId: questionId);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
