import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

/// Kırmızı listedeki tek kayıt. Alan adları `StudentAbsenceRecordEntity` ile aynıdır.
class CriticalAbsenceItem {
  /// [absencePercentage] ve [isCriticalRisk] verilmezse saatlerden hesaplanır
  /// (Kural 3: %20 ve üzeri → Kritik Risk).
  CriticalAbsenceItem({
    required this.studentUid,
    required this.studentName,
    required this.studentNo,
    required this.courseName,
    required this.absentHours,
    required this.totalCourseHours,
    this.courseId,
    double? absencePercentage,
    bool? isCriticalRisk,
  }) : absencePercentage = absencePercentage ?? _percent(absentHours, totalCourseHours),
       isCriticalRisk =
           isCriticalRisk ??
           (absencePercentage ?? _percent(absentHours, totalCourseHours)) >= CriticalAbsenceRedList.criticalThreshold;

  final String studentUid;
  final String studentName;
  final String studentNo;
  final String? courseId;
  final String courseName;
  final int absentHours;
  final int totalCourseHours;
  final double absencePercentage;
  final bool isCriticalRisk;

  static double _percent(int absent, int total) => total > 0 ? absent / total * 100 : 0;

  /// %20'ye yaklaşan ama henüz aşmayan öğrenci.
  bool get isApproaching => !isCriticalRisk && absencePercentage >= CriticalAbsenceRedList.warningThreshold;
}

/// [CriticalAbsenceRedList] — Kural 3 **%20 Kritik Risk kırmızı uyarı listesi**.
///
/// %20 sınırını aşan öğrenciler kırmızı, sınıra yaklaşanlar (%15+) turuncu
/// vurgulanır; liste devamsızlık yüzdesine göre azalan sıralanır. Eğitmen
/// [onSendPushWarning] ile öğrenciye "Kritik Devamsızlık Riski!" push bildirimi gönderir.
class CriticalAbsenceRedList extends StatelessWidget {
  const CriticalAbsenceRedList({super.key, required this.atRiskStudents, this.onSendPushWarning});

  static const double criticalThreshold = 20.0;
  static const double warningThreshold = 15.0;

  final List<CriticalAbsenceItem> atRiskStudents;
  final void Function(CriticalAbsenceItem student)? onSendPushWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final visible = atRiskStudents.where((s) => s.isCriticalRisk || s.isApproaching).toList()
      ..sort((a, b) => b.absencePercentage.compareTo(a.absencePercentage));
    final criticalCount = visible.where((s) => s.isCriticalRisk).length;

    if (visible.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
        padding: AppDimensions.paddingAll16,
        decoration: BoxDecoration(
          color: AppColors.resolvedGreen.withValues(alpha: isDark ? 0.2 : 0.08),
          borderRadius: AppDimensions.radius16,
          border: Border.all(color: AppColors.resolvedGreen.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.resolvedGreen, size: 22),
            SizedBox(width: AppDimensions.p12),
            Expanded(
              child: Text(
                'Tebrikler! Sınıfta %20 devamsızlık sınırını aşan öğrenci bulunmuyor.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.criticalAbsenceRed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kritik Risk Kırmızı Liste (%20 Devamsızlık)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.criticalAbsenceRed,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.criticalAbsenceRed, borderRadius: AppDimensions.radiusFull),
                child: Text(
                  '$criticalCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p4),
          child: Column(
            children: [for (final student in visible) _RiskRow(student: student, onSendPushWarning: onSendPushWarning)],
          ),
        ),
      ],
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({required this.student, required this.onSendPushWarning});

  final CriticalAbsenceItem student;
  final void Function(CriticalAbsenceItem student)? onSendPushWarning;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCritical = student.isCriticalRisk;
    final color = isCritical ? AppColors.criticalAbsenceRed : AppColors.warningAmber;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isCritical ? AppColors.criticalAbsenceRed.withValues(alpha: isDark ? 0.12 : 0.04) : null,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.radius12,
        side: BorderSide(color: color, width: isCritical ? 1.2 : 1),
      ),
      child: Padding(
        padding: AppDimensions.paddingAll12,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(isCritical ? Icons.person_off_rounded : Icons.trending_up_rounded, color: color, size: 18),
            ),
            const SizedBox(width: AppDimensions.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Text(
                    '${student.studentNo} • ${student.courseName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '%${student.absencePercentage.toStringAsFixed(1)} Devamsızlık '
                    '(${student.absentHours}/${student.totalCourseHours} saat)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                  ),
                  if (!isCritical)
                    const Text(
                      'Sınıra yaklaşıyor',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warningAmber),
                    ),
                ],
              ),
            ),
            if (onSendPushWarning != null)
              IconButton(
                icon: const Icon(Icons.notification_add_rounded),
                color: color,
                tooltip: isCritical ? '${AppStrings.criticalRiskBadge} — Push Bildirimi Gönder' : 'Uyarı Gönder',
                onPressed: () => onSendPushWarning!(student),
              ),
          ],
        ),
      ),
    );
  }
}
