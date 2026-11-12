import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// [StudentAbsenceProgressCard] öğrencinin ders bazlı devamsızlık ilerleme kartıdır.
///
/// Hangi dersten kaç saat ve yüzde kaç devamsızlığı olduğunu, %20 sınırına
/// (Kural 3) ne kadar yaklaştığını ve sınıra kadar kalan saat hakkını gösterir.
/// İlerleme çubuğunun üzerindeki çizgi %20 sınırını işaretler.
class StudentAbsenceProgressCard extends StatelessWidget {
  const StudentAbsenceProgressCard({
    super.key,
    required this.courseName,
    required this.totalCourseHours,
    required this.absentHours,
    this.onTap,
  });

  /// Kural 3: kritik devamsızlık sınırı (%).
  static const double criticalThreshold = 20.0;

  /// Bu yüzdeden itibaren "Dikkat" uyarısı gösterilir.
  static const double warningThreshold = 15.0;

  final String courseName;
  final int totalCourseHours;
  final int absentHours;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final ratio = totalCourseHours > 0 ? (absentHours / totalCourseHours).clamp(0.0, 1.0) : 0.0;
    final percentage = ratio * 100;
    final isCritical = percentage >= criticalThreshold;
    final isWarning = !isCritical && percentage >= warningThreshold;
    final allowedHours = (totalCourseHours * criticalThreshold / 100).floor();
    final remainingHours = (allowedHours - absentHours).clamp(0, totalCourseHours);

    final statusColor = isCritical
        ? AppColors.criticalAbsenceRed
        : (isWarning ? AppColors.warningAmber : AppColors.secondaryLight);
    final statusLabel = isCritical ? 'Kritik Risk (%20+)' : (isWarning ? 'Dikkat' : 'Güvende');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.radius16,
        side: BorderSide(
          color: isCritical ? AppColors.criticalAbsenceRed : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isCritical ? 1.5 : 1,
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
              LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        courseName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.p8),
                    // Rozet satırın en fazla %55'ini kaplar; büyük yazıda kesilmeden küçülür.
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.55),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: isDark ? 0.25 : 0.12),
                            borderRadius: AppDimensions.radiusFull,
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.p12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Devamsızlık: $absentHours / $totalCourseHours saat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.p8),
                  Text(
                    '%${percentage.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: statusColor),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.p8),
              _ThresholdProgressBar(ratio: ratio, color: statusColor, isDark: isDark),
              const SizedBox(height: AppDimensions.p6),
              Text(
                isCritical
                    ? '%20 sınırı aşıldı — danışmanınızla görüşünüz.'
                    : 'Sınıra kadar kalan hak: $remainingHours saat',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCritical ? FontWeight.w700 : FontWeight.w500,
                  color: isCritical ? AppColors.criticalAbsenceRed : muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// İlerleme çubuğu + %20 sınır işareti.
class _ThresholdProgressBar extends StatelessWidget {
  const _ThresholdProgressBar({required this.ratio, required this.color, required this.isDark});

  final double ratio;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Devamsızlık yüzde ${(ratio * 100).toStringAsFixed(0)}, sınır yüzde 20',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final markerX = constraints.maxWidth * StudentAbsenceProgressCard.criticalThreshold / 100;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  ClipRRect(
                    borderRadius: AppDimensions.radiusFull,
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Positioned(
                    left: markerX - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: AppColors.criticalAbsenceRed,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
