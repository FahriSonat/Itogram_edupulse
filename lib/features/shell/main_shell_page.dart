import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_strings.dart';
import '../../core/router/route_names.dart';
import '../../core/widgets/main_scaffold_shell.dart';
import '../announcements/presentation/pages/home_announcements_page.dart';
import '../assignments/presentation/pages/assignment_control_page.dart';
import '../auth/domain/entities/user_entity.dart';
import '../auth/presentation/cubit/auth_cubit.dart';
import '../forum/presentation/pages/forum_page.dart';
import '../grades/presentation/pages/grade_info_page.dart';
import '../notifications/presentation/cubit/notification_cubit.dart';
import '../notifications/presentation/widgets/notifications_sheet.dart';
import '../schedule/presentation/pages/weekly_schedule_page.dart';

/// [MainShellPage] oturum açıldıktan sonraki ana kabuk: 5 sekmeli alt menü,
/// yan menü (drawer), bildirim zili ve sekmeye özel eylem düğmesi.
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key, required this.user});

  final UserEntity user;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _index = 0;

  UserEntity get _user => widget.user;

  void _goTo(int index) => setState(() => _index = index);

  void _onDrawerNavigate(String route) {
    switch (route) {
      case RouteNames.home:
        _goTo(0);
      case RouteNames.schedule:
        _goTo(1);
      case RouteNames.assignments:
        _goTo(2);
      case RouteNames.forum:
        _goTo(3);
      case RouteNames.grades:
      case RouteNames.profile:
        _goTo(4);
      default:
        Navigator.of(context).pushNamed(route);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.navLogout),
        content: const Text('Oturumu kapatmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppStrings.navLogout)),
        ],
      ),
    );
    if (ok == true && mounted) await context.read<AuthCubit>().logout();
  }

  String get _title => switch (_index) {
    1 => AppStrings.navSchedule,
    2 => AppStrings.navAssignments,
    3 => AppStrings.navForum,
    4 => _user.isStudent ? 'Profil & Notlar' : 'Sınıf Analizi & Notlar',
    _ => AppStrings.appName,
  };

  Widget? _fab() {
    switch (_index) {
      case 1 when _user.isInstructor:
        return FloatingActionButton.extended(
          heroTag: 'fab_schedule',
          onPressed: () => WeeklySchedulePage.openEditor(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ders Ekle'),
        );
      case 2 when _user.isInstructor:
        return FloatingActionButton.extended(
          heroTag: 'fab_assignment',
          onPressed: () => AssignmentControlPage.openCreateSheet(context),
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Yeni Ödev'),
        );
      case 3:
        return FloatingActionButton.extended(
          heroTag: 'fab_forum',
          onPressed: () => ForumPage.openAskQuestion(context),
          icon: const Icon(Icons.add_comment_rounded),
          label: const Text('Soru Sor'),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<NotificationCubit, int>((c) => c.state.unreadCount);

    return MainScaffoldShell(
      title: _title,
      currentIndex: _index,
      userRole: _user.role,
      userName: _user.fullName,
      userEmailOrNo: _user.subtitle,
      unreadNotifications: unread,
      onNotificationPressed: () => NotificationsSheet.show(context),
      onNavigationIndexChanged: _goTo,
      onDrawerNavigate: _onDrawerNavigate,
      onLogout: _logout,
      floatingActionButton: _fab(),
      child: IndexedStack(
        index: _index,
        children: [
          HomeAnnouncementsPage(onNavigateTab: _goTo),
          const WeeklySchedulePage(),
          const AssignmentControlPage(),
          const ForumPage(),
          const GradeInfoPage(),
        ],
      ),
    );
  }
}
