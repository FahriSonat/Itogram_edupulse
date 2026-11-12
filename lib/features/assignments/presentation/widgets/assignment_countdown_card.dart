import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/submission_status.dart';
import '../../../../core/widgets/countdown_timer_widget.dart';
import 'late_submission_warning_banner.dart';

/// Ödev teslim durumu ikonları.
IconData submissionStatusIcon(SubmissionStatus status) => switch (status) {
  SubmissionStatus.pending => Icons.pending_outlined,
  SubmissionStatus.submitted => Icons.check_circle_outline_rounded,
  SubmissionStatus.graded => Icons.verified_outlined,
  SubmissionStatus.late => Icons.access_time_filled_rounded,
  SubmissionStatus.missing => Icons.cancel_outlined,
};

/// [AssignmentCountdownCard] son teslim geri sayaçlı ödev kartıdır.
///
/// Ders etiketi, teslim durumu rozeti (Bekliyor / Teslim Edildi / Gecikti),
/// canlı geri sayım ve öğrenci için yükleme butonu içerir. Son tarih geçmişse
/// yükleme engellenmez; buton "Geç Teslim Et" olur ve kırmızı ceza rozeti görünür.
class AssignmentCountdownCard extends StatelessWidget {
  const AssignmentCountdownCard({
    super.key,
    required this.title,
    required this.courseName,
    required this.description,
    required this.dueDate,
    this.status = SubmissionStatus.pending,
    this.onTap,
    this.onSubmitPressed,
    this.now,
  });

  final String title;
  final String courseName;
  final String description;
  final DateTime dueDate;
  final SubmissionStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onSubmitPressed;

  /// Test / önizleme için "şimdi" (varsayılan: `DateTime.now()`).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final isPastDue = (now ?? DateTime.now()).isAfter(dueDate);
    final isSubmitted = status == SubmissionStatus.submitted || status == SubmissionStatus.graded;
    final showLateBadge = status == SubmissionStatus.late || (isPastDue && !isSubmitted);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.radius16,
        side: BorderSide(
          color: showLateBadge
              ? AppColors.lateSubmissionOrange
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.radius16,
        child: Padding(
          padding: AppDimensions.paddingAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: AppDimensions.radiusFull,
                      ),
                      child: Text(
                        courseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.p8),
                  _StatusBadge(status: status, isDark: isDark),
                ],
              ),
              const SizedBox(height: AppDimensions.p10),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (showLateBadge) ...[
                const SizedBox(height: AppDimensions.p8),
                const LateSubmissionWarningBanner.badge(),
              ],
              const SizedBox(height: AppDimensions.p12),
              LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CountdownTimerWidget(targetDateTime: dueDate, isCompact: true),
                      ),
                    ),
                    if (!isSubmitted && onSubmitPressed != null) ...[
                      const SizedBox(width: AppDimensions.p8),
                      // Buton doğal boyutunda durur; dar ekran / büyük yazıda satırın
                      // %60'ını aşacaksa taşmak yerine küçülür.
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ElevatedButton.icon(
                            onPressed: onSubmitPressed,
                            icon: const Icon(Icons.upload_file_rounded, size: 16),
                            label: Text(
                              isPastDue ? 'Geç Teslim Et' : 'Ödevi Yükle',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor: isPastDue ? AppColors.lateSubmissionOrange : primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isDark});

  final SubmissionStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forSubmissionStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: AppDimensions.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(submissionStatusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            AppStrings.submissionStatus(status),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
