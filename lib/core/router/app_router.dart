import 'package:flutter/material.dart';

import '../../features/assignments/presentation/pages/submission_grading_detail_page.dart';
import '../../features/attendance/presentation/pages/absence_control_page.dart';
import '../../features/attendance/presentation/pages/live_attendance_page.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/forum/presentation/pages/forum_question_detail_page.dart';
import '../constants/app_strings.dart';
import '../widgets/state_views/error_state_view.dart';
import 'role_guard.dart';
import 'route_names.dart';

/// [AppRouter] adlandırılmış rotaları sayfalara eşler ve Kural 5 gereği
/// eğitmene özel rotalara yetkisiz erişimi engeller.
class AppRouter {
  AppRouter(this._authCubit);

  final AuthCubit _authCubit;

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final role = _authCubit.state.user?.role;
    if (!RoleGuard.canAccess(settings.name, role)) {
      return _page(settings, const _UnauthorizedPage());
    }

    final Widget? page = switch (settings.name) {
      RouteNames.register => const RegisterPage(),
      RouteNames.forgotPassword => const ForgotPasswordPage(),
      RouteNames.liveAttendance => const LiveAttendancePage(),
      RouteNames.absenceControl => const AbsenceControlPage(),
      RouteNames.submissionGrading when settings.arguments is String => SubmissionGradingDetailPage(
        assignmentId: settings.arguments! as String,
      ),
      RouteNames.forumQuestionDetail when settings.arguments is String => ForumQuestionDetailPage(
        questionId: settings.arguments! as String,
      ),
      _ => null,
    };
    return page == null ? null : _page(settings, page);
  }

  Route<dynamic> onUnknownRoute(RouteSettings settings) => _page(
    settings,
    Scaffold(
      appBar: AppBar(),
      body: ErrorStateView(title: 'Sayfa bulunamadı', message: '"${settings.name}" adresinde bir sayfa yok.'),
    ),
  );

  static MaterialPageRoute<dynamic> _page(RouteSettings settings, Widget page) =>
      MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
}

class _UnauthorizedPage extends StatelessWidget {
  const _UnauthorizedPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Erişim Engellendi')),
    body: ErrorStateView(
      icon: Icons.lock_outline_rounded,
      title: 'Yetkisiz Erişim',
      message: AppStrings.unauthorizedAccess,
      onRetry: () => Navigator.of(context).maybePop(),
    ),
  );
}
