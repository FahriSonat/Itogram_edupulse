import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../edu_card.dart';

/// [MetricBadgeCard] mockup'taki hızlı metrik kutularıdır:
/// %92 Ders Katılımı (yeşil), 3 Aktif Ödev (mor), 3.42 GPA (pembe).
///
/// - Aydınlık: pastel zemin ([tileColor]) + dolu renkli ikon dairesi.
/// - Karanlık: lacivert kart, [accentColor] tonunda ince parlayan kenarlık.
class MetricBadgeCard extends StatelessWidget {
  const MetricBadgeCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.accentColor,
    this.tileColor,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accentColor;

  /// Aydınlık temadaki pastel zemin. Null ise [accentColor]'ın %10'u kullanılır.
  final Color? tileColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return EduCard(
      tint: tileColor ?? accentColor.withValues(alpha: 0.1),
      glowColor: accentColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(color: accentColor.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
