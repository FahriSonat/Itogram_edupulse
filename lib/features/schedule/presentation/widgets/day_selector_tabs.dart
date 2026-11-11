import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// [DaySelectorTabs] mockup'taki segmentli gün seçicisidir (Pzt, Sal, Çar, Per, Cum).
///
/// - Aydınlık: beyaz kapsül içinde turuncu tonlu seçili hap.
/// - Karanlık: lacivert kapsül içinde dolu elektrik mavisi hap + hale.
class DaySelectorTabs extends StatelessWidget {
  const DaySelectorTabs({
    super.key,
    required this.selectedDayIndex,
    required this.onDaySelected,
    this.includeWeekend = false,
  });

  /// 1 = Pazartesi … 7 = Pazar
  final int selectedDayIndex;
  final ValueChanged<int> onDaySelected;
  final bool includeWeekend;

  static const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = includeWeekend ? 7 : 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: AppDimensions.radius16,
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.dividerLight),
          boxShadow: isDark
              ? null
              : const [BoxShadow(color: AppColors.softShadowLight, blurRadius: 18, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            for (var i = 0; i < count; i++)
              Expanded(
                child: _DayChip(
                  label: _days[i],
                  isSelected: selectedDayIndex == i + 1,
                  isDark: isDark,
                  onTap: () => onDaySelected(i + 1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.isSelected, required this.isDark, required this.onTap});

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    final BoxDecoration decoration;
    if (isSelected && isDark) {
      textColor = Colors.white;
      decoration = BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: AppDimensions.radius12,
        boxShadow: [
          BoxShadow(color: AppColors.glowBlue.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      );
    } else if (isSelected) {
      textColor = AppColors.accentWarm;
      decoration = BoxDecoration(
        color: AppColors.accentWarm.withValues(alpha: 0.12),
        borderRadius: AppDimensions.radius12,
      );
    } else {
      textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
      decoration = const BoxDecoration(borderRadius: AppDimensions.radius12);
    }

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.radius12,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: decoration,
          child: Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: textColor),
          ),
        ),
      ),
    );
  }
}
