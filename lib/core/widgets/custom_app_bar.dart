import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../enums/user_role.dart';
import 'brand/edupulse_logo.dart';

/// [CustomAppBar] tüm ekranların ortak üst barıdır.
///
/// Aktif ekran başlığını ve sağ üst köşede kullanıcının aktif rolünü
/// (`ÖĞRENCİ PORTALI` veya `EĞİTMEN YÖNETİM PANELİ`) renkli rozet olarak gösterir.
/// Rozet her ekran genişliğinde tam metinle görünür; dar ekranda taşmak yerine küçülür.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.currentRole,
    this.actions,
    this.showBackButton = true,
    this.onNotificationPressed,
    this.unreadNotificationCount = 0,
  });

  final String title;
  final UserRole? currentRole;
  final List<Widget>? actions;
  final bool showBackButton;

  /// Verilirse sağda bildirim zili gösterilir.
  final VoidCallback? onNotificationPressed;
  final int unreadNotificationCount;

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();
    final hasDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;

    Widget? leading;
    if (showBackButton && canPop) {
      leading = IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
      );
    } else if (hasDrawer) {
      leading = IconButton(
        icon: const Icon(Icons.menu_rounded, size: 24),
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: () => Scaffold.of(context).openDrawer(),
      );
    }

    // Şeffaf bar: arkadaki AmbientBackground / sahne kesintisiz görünür.
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: leading,
      titleSpacing: leading == null ? AppDimensions.p16 : 0,
      // Logo, sağdaki aksiyonlar kalabalıklaştığında taşmak yerine küçülür.
      title: title == AppStrings.appName
          ? const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: EduPulseLogo(size: 26, showText: true),
            )
          : Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
      actions: [
        ...?actions,
        if (currentRole != null) RoleBadge(role: currentRole!),
        if (onNotificationPressed != null) _buildNotificationButton(isDark),
        const SizedBox(width: AppDimensions.p8),
      ],
    );
  }

  Widget _buildNotificationButton(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            size: 24,
          ),
          onPressed: onNotificationPressed,
          tooltip: AppStrings.notifications,
        ),
        if (unreadNotificationCount > 0)
          Positioned(
            top: 10,
            right: 10,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.p4),
                decoration: const BoxDecoration(color: AppColors.criticalAbsenceRed, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadNotificationCount > 9 ? '9+' : '$unreadNotificationCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Aktif rol rozeti: `ÖĞRENCİ PORTALI` (mavi) / `EĞİTMEN YÖNETİM PANELİ` (mor) / `YÖNETİCİ PANELİ` (camgöbeği).
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (badgeColor, lightBg, darkBg, icon) = switch (role) {
      UserRole.student => (
        AppColors.studentRoleBadge,
        AppColors.studentRoleBackground,
        const Color(0xFF1E3A8A),
        Icons.school_rounded,
      ),
      UserRole.instructor => (
        AppColors.instructorRoleBadge,
        AppColors.instructorRoleBackground,
        const Color(0xFF4C1D95),
        Icons.admin_panel_settings_rounded,
      ),
      UserRole.admin => (
        AppColors.infoBlue,
        const Color(0xFFE0F2FE),
        const Color(0xFF0C4A6E),
        Icons.verified_user_rounded,
      ),
    };
    final textColor = isDark ? Color.lerp(badgeColor, Colors.white, 0.35)! : badgeColor;
    final bgColor = isDark ? darkBg.withValues(alpha: 0.4) : lightBg;
    final label = AppStrings.portalBadge(role);

    // Tam metin her zaman gösterilir; dar ekranlarda başlığa yer bırakmak için
    // rozet ekran genişliğinin en fazla ~%40'ını kaplar ve gerekirse küçülür.
    final maxWidth = MediaQuery.sizeOf(context).width * 0.4;

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p8, vertical: AppDimensions.p4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppDimensions.radiusFull,
                border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: textColor),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: textColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
