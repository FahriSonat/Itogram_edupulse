import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';

/// [ErrorStateView] — 4 Durum Kalkanı: **Error**.
///
/// Hata oluştuğunda uyarı ikonu, başlık, açıklama ve [onRetry] verilmişse
/// "Tekrar Dene" butonu gösterir. İçerik kaydırılabilir; taşma üretmez.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, this.title, this.message, this.onRetry, this.icon = Icons.error_outline_rounded});

  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  static const String defaultTitle = 'Bir Sorun Oluştu';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: AppDimensions.paddingAll24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.p20),
              decoration: BoxDecoration(
                color: AppColors.criticalAbsenceRed.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.criticalAbsenceRed, size: AppDimensions.iconHero),
            ),
            const SizedBox(height: AppDimensions.p16),
            Text(
              title ?? defaultTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.p8),
            Text(
              message ?? AppStrings.errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.p24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(AppStrings.retryButton),
                style: ElevatedButton.styleFrom(minimumSize: const Size(160, AppDimensions.buttonHeightSm)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
