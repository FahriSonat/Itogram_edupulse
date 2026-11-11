import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../enums/user_role.dart';
import 'app_drawer_menu.dart';
import 'atmosphere/ambient_background.dart';
import 'custom_app_bar.dart';

/// [MainScaffoldShell] uygulamanın ana çerçevesidir:
/// üstte [CustomAppBar], solda açılır-kapanır [AppDrawerMenu] ve altta hızlı
/// erişim sağlayan kalıcı [BottomNavigationBar].
///
/// GoRouter `ShellRoute` ile kullanım:
/// ```dart
/// ShellRoute(
///   builder: (context, state, child) => MainScaffoldShell(
///     title: ...,
///     currentRoute: state.uri.path,
///     currentIndex: MainScaffoldShell.indexForRoute(state.uri.path),
///     onNavigationIndexChanged: (i) => context.go(MainScaffoldShell.tabRoutes[i]),
///     onDrawerNavigate: context.go,
///     ...
///     child: child,
///   ),
/// )
/// ```
class MainScaffoldShell extends StatelessWidget {
  const MainScaffoldShell({
    super.key,
    required this.child,
    required this.title,
    required this.userRole,
    required this.userName,
    required this.userEmailOrNo,
    required this.onNavigationIndexChanged,
    required this.onDrawerNavigate,
    required this.onLogout,
    this.currentIndex = 0,
    this.currentRoute,
    this.onNotificationPressed,
    this.unreadNotifications = 0,
    this.appBarActions,
    this.floatingActionButton,
  });

  /// Alt menü sekmelerinin rota karşılıkları (şartname `route_names` ile aynı).
  static const List<String> tabRoutes = ['/home', '/schedule', '/assignments', '/forum', '/grades'];

  /// Rota → alt menü sekmesi. Sekmesi olmayan rotalar (ör. `/live-attendance`)
  /// için `-1` döner; bu durumda alt menüde son seçili sekme korunmalıdır.
  static int indexForRoute(String route) {
    for (var i = 0; i < tabRoutes.length; i++) {
      if (route == tabRoutes[i] || route.startsWith('${tabRoutes[i]}/')) return i;
    }
    return -1;
  }

  final Widget child;
  final String title;
  final int currentIndex;

  /// Yan menüde vurgulanacak rota. Verilmezse [currentIndex] sekmesinin rotası kullanılır.
  final String? currentRoute;
  final UserRole userRole;
  final String userName;
  final String userEmailOrNo;
  final ValueChanged<int> onNavigationIndexChanged;
  final void Function(String routeName) onDrawerNavigate;
  final VoidCallback onLogout;
  final VoidCallback? onNotificationPressed;
  final int unreadNotifications;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;

  static const List<_TabItem> _tabs = [
    _TabItem(Icons.home_outlined, Icons.home_rounded, AppStrings.tabHome),
    _TabItem(Icons.calendar_today_outlined, Icons.calendar_today_rounded, AppStrings.tabSchedule),
    _TabItem(Icons.assignment_outlined, Icons.assignment_rounded, AppStrings.tabAssignments),
    _TabItem(Icons.forum_outlined, Icons.forum_rounded, AppStrings.tabForum),
    _TabItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, AppStrings.tabGrades),
  ];

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, _tabs.length - 1);

    // AmbientBackground tüm modül ekranlarının arkasına ortam ışığını çizer;
    // Scaffold ve AppBar şeffaf olduğundan atmosfer kesintisiz görünür.
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          title: title,
          currentRole: userRole,
          showBackButton: false,
          actions: appBarActions,
          onNotificationPressed: onNotificationPressed,
          unreadNotificationCount: unreadNotifications,
        ),
        drawer: AppDrawerMenu(
          currentRoute: currentRoute ?? tabRoutes[safeIndex],
          userName: userName,
          userEmailOrNo: userEmailOrNo,
          userRole: userRole,
          onNavigate: onDrawerNavigate,
          onLogout: onLogout,
        ),
        body: child,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: _PersistentBottomNavigationBar(
          tabs: _tabs,
          currentIndex: safeIndex,
          onTap: onNavigationIndexChanged,
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Kalıcı alt menü: Flutter [BottomNavigationBar]; seçili sekme mockup'taki
/// yumuşak hap (pill) zemin ile vurgulanır. Renkler `bottomNavigationBarTheme`'den gelir.
class _PersistentBottomNavigationBar extends StatelessWidget {
  const _PersistentBottomNavigationBar({required this.tabs, required this.currentIndex, required this.onTap});

  final List<_TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.dividerLight)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.35) : AppColors.softShadowLight,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        items: [
          for (final tab in tabs)
            BottomNavigationBarItem(
              icon: _PillIcon(icon: tab.icon, selected: false),
              activeIcon: _PillIcon(icon: tab.activeIcon, selected: true),
              label: tab.label,
              tooltip: tab.label,
            ),
        ],
      ),
    );
  }
}

class _PillIcon extends StatelessWidget {
  const _PillIcon({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // BottomNavigationBar seçili/seçisiz rengi IconTheme ile aktarır.
    final color = IconTheme.of(context).color ?? Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: isDark ? 0.2 : 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        boxShadow: selected && isDark ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)] : null,
      ),
      child: Icon(icon, size: 23),
    );
  }
}
