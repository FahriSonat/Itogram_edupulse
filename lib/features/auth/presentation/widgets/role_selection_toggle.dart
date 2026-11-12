import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';

/// [RoleSelectionToggle] kayıt / giriş aşamasında **"Öğrenci / Kursiyer"** ile
/// **"Eğitmen / Yönetici"** rolünü seçtiren interaktif kart bileşenidir.
class RoleSelectionToggle extends StatelessWidget {
  const RoleSelectionToggle({super.key, required this.selectedRole, required this.onRoleChanged});

  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _RoleCard(
            role: UserRole.student,
            title: AppStrings.studentRole,
            subtitle: 'Ders, ödev & not takibi',
            icon: Icons.school_rounded,
            isSelected: selectedRole == UserRole.student,
            primaryColor: AppColors.studentRoleBadge,
            onTap: () => onRoleChanged(UserRole.student),
          ),
        ),
        const SizedBox(width: AppDimensions.p12),
        Expanded(
          child: _RoleCard(
            role: UserRole.instructor,
            title: AppStrings.instructorRole,
            subtitle: 'Yoklama & sınıf yönetimi',
            icon: Icons.badge_outlined,
            isSelected: selectedRole == UserRole.instructor,
            primaryColor: AppColors.instructorRoleBadge,
            onTap: () => onRoleChanged(UserRole.instructor),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  final UserRole role;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? Color.lerp(primaryColor, Colors.white, 0.3)! : primaryColor;

    return Semantics(
      button: true,
      selected: isSelected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.radius16,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: AppDimensions.paddingAll16,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
                : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: AppDimensions.radius16,
            border: Border.all(
              color: isSelected ? accent : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: primaryColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.p8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isSelected ? 0.25 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: AppDimensions.iconMd, color: accent),
                  ),
                  if (isSelected) Icon(Icons.check_circle_rounded, color: accent, size: 20),
                ],
              ),
              const SizedBox(height: AppDimensions.p12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? accent : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
