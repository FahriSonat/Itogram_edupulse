import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

/// [LateSubmissionWarningBanner] — Kural 2 (Ödev Zaman Kalkanı & Ceza).
///
/// Son teslim tarihi geçmiş ödevlerde sistem yüklemeyi engellemez; bu bileşen
/// kırmızı **"GECİKMİŞ TESLİM (-10 Ceza Puanı)"** rozetini ve açıklamasını gösterir.
/// - Varsayılan: Gecikmiş Teslim Turuncusu çerçeveli tam uyarı bandı.
/// - [LateSubmissionWarningBanner.badge]: kart/listelerde kullanılan yalnızca kırmızı rozet.
class LateSubmissionWarningBanner extends StatelessWidget {
  const LateSubmissionWarningBanner({super.key, this.penaltyPoints = 10, this.message}) : isCompact = false;

  /// Yalnızca kırmızı "GECİKMİŞ TESLİM (-10 Ceza Puanı)" rozeti.
  const LateSubmissionWarningBanner.badge({super.key, this.penaltyPoints = 10}) : isCompact = true, message = null;

  final int penaltyPoints;
  final bool isCompact;

  /// Bant açıklaması (varsayılan: [AppStrings.lateSubmissionWarning]).
  final String? message;

  /// Rozet metni — varsayılan ceza ile `AppStrings.lateSubmissionBadge` ile aynıdır.
  static String badgeText(int penaltyPoints) => 'GECİKMİŞ TESLİM (-$penaltyPoints Ceza Puanı)';

  @override
  Widget build(BuildContext context) {
    if (isCompact) return _PenaltyBadge(text: badgeText(penaltyPoints));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      padding: AppDimensions.paddingAll16,
      decoration: BoxDecoration(
        color: AppColors.lateSubmissionOrange.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: AppDimensions.radius16,
        border: Border.all(color: AppColors.lateSubmissionOrange.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.p8),
            decoration: BoxDecoration(
              color: AppColors.criticalAbsenceRed.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.criticalAbsenceRed, size: 20),
          ),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PenaltyBadge(text: badgeText(penaltyPoints)),
                const SizedBox(height: AppDimensions.p6),
                Text(
                  message ?? AppStrings.lateSubmissionWarning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PenaltyBadge extends StatelessWidget {
  const _PenaltyBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.criticalAbsenceRed, borderRadius: AppDimensions.radius4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
