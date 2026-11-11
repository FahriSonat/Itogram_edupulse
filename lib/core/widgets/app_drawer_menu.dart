import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../enums/user_role.dart';
import '../theme/theme_cubit.dart';
import 'atmosphere/campus_scene.dart';
import 'dashboard/portal_avatar.dart';
import 'theme_toggle_switch.dart';

/// Yan menüdeki tek bir ekran bağlantısı.
class DrawerDestination {
  const DrawerDestination({required this.route, required this.title, required this.icon});

  final String route;
  final String title;
  final IconData icon;
}

/// [AppDrawerMenu] şartnamedeki **MENÜ EKRANI (AÇILIR KAPANIR)** bileşenidir.
///
/// Kullanıcı profil özetini ve 7 ekran bağlantısını listeler:
/// Ana Sayfa (Duyurular), 2.1 Ders Programı, 2.2 Canlı Yoklama, 2.3 Ödev Kontrol,
/// 2.4 Devamsızlık Kontrol, 2.5 Not Bilgisi, 2.6 Kampüs Forumu;
/// altta Tema Değiştirici ve Çıkış Yap butonu bulunur.
class AppDrawerMenu extends StatelessWidget {
  const AppDrawerMenu({
    super.key,
    required this.currentRoute,
    required this.userName,
    required this.userEmailOrNo,
    required this.userRole,
    required this.onNavigate,
    required this.onLogout,
  });

  final String currentRoute;
  final String userName;
  final String userEmailOrNo;
  final UserRole userRole;
  final void Function(String routeName) onNavigate;
  final VoidCallback onLogout;

  /// Şartnamedeki sırayla 7 ekran bağlantısı (rotalar `route_names` ile aynı).
  static const List<DrawerDestination> destinations = [
    DrawerDestination(route: '/home', title: AppStrings.drawerHome, icon: Icons.campaign_rounded),
    DrawerDestination(route: '/schedule', title: AppStrings.drawerSchedule, icon: Icons.calendar_month_rounded),
    DrawerDestination(
      route: '/live-attendance',
      title: AppStrings.drawerLiveAttendance,
      icon: Icons.qr_code_scanner_rounded,
    ),
    DrawerDestination(route: '/assignments', title: AppStrings.drawerAssignments, icon: Icons.assignment_outlined),
    DrawerDestination(route: '/absence-control', title: AppStrings.drawerAbsence, icon: Icons.access_time_rounded),
    DrawerDestination(route: '/grades', title: AppStrings.drawerGrades, icon: Icons.auto_graph_rounded),
    DrawerDestination(route: '/forum', title: AppStrings.drawerForum, icon: Icons.forum_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
      // Üst güvenli alan sahne tarafından doldurulur (gökyüzü durum çubuğunun altına uzanır).
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildProfileHeader(context, isDark),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p12, vertical: AppDimensions.p8),
                children: [for (final d in destinations) _buildDrawerItem(context, d, isDark)],
              ),
            ),
            const Divider(height: 1),
            _buildThemeSwitcher(context, isDark),
            _buildLogoutButton(context),
            const SizedBox(height: AppDimensions.p8),
          ],
        ),
      ),
    );
  }

  /// Kampüs sahnesi "kapak" + üstüne binen avatar + kimlik bilgileri.
  Widget _buildProfileHeader(BuildContext context, bool isDark) {
    final isStudent = userRole == UserRole.student;
    final roleColor = isStudent ? AppColors.studentRoleBadge : AppColors.instructorRoleBadge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 96 + MediaQuery.paddingOf(context).top,
              child: const CampusScene(buildingCenterX: 0.66, buildingHeight: 52, groundInset: 10),
            ),
            Positioned(
              left: AppDimensions.p16,
              bottom: -28,
              child: PortalAvatar(role: userRole, size: 60),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.p16, 36, AppDimensions.p16, AppDimensions.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                userEmailOrNo,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: AppDimensions.radiusFull,
                ),
                child: Text(
                  AppStrings.portalBadge(userRole),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Color.lerp(roleColor, Colors.white, 0.4) : roleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem(BuildContext context, DrawerDestination destination, bool isDark) {
    final isSelected = currentRoute == destination.route;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    // Arka plan ListTile'ın kendi tileColor'ı ile verilir; araya renkli bir
    // Container koymak ripple efektini gizler.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedTileColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        leading: Icon(
          destination.icon,
          color: isSelected ? primaryColor : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          size: 22,
        ),
        title: Text(
          destination.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? primaryColor : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            fontSize: 14,
          ),
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
        onTap: () {
          Navigator.of(context).pop(); // Menüyü kapat
          onNavigate(destination.route);
        },
      ),
    );
  }

  Widget _buildThemeSwitcher(BuildContext context, bool isDark) {
    ThemeCubit? themeCubit;
    try {
      themeCubit = BlocProvider.of<ThemeCubit>(context, listen: false);
    } catch (_) {
      themeCubit = null; // Ağaçta ThemeCubit yoksa anahtar pasif görünür.
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 20,
            color: isDark ? AppColors.accentDark : AppColors.accentLight,
          ),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Text(
              isDark ? AppStrings.themeDark : AppStrings.themeLight,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          ThemeToggleSwitch(isDark: isDark, onChanged: (_) => themeCubit?.toggleTheme()),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p12),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.logout_rounded, color: AppColors.criticalAbsenceRed, size: 22),
        title: const Text(
          AppStrings.navLogout,
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.criticalAbsenceRed, fontSize: 14),
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
        onTap: () {
          Navigator.of(context).pop();
          onLogout();
        },
      ),
    );
  }
}
