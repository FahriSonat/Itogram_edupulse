import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/announcement_type.dart';

/// Duyuru türü ikonları (Genel / Sınav / Ödev / Etkinlik / Acil).
IconData announcementTypeIcon(AnnouncementType type) => switch (type) {
  AnnouncementType.general => Icons.campaign_outlined,
  AnnouncementType.exam => Icons.quiz_outlined,
  AnnouncementType.assignment => Icons.assignment_outlined,
  AnnouncementType.event => Icons.celebration_outlined,
  AnnouncementType.urgent => Icons.warning_amber_rounded,
};

/// [AnnouncementCard] Genel / Sınav / Ödev / Etkinlik / Acil rozetli duyuru kartıdır.
///
/// Alanlar `AnnouncementEntity` ile birebir eşleşir: `title`, `content`, `type`,
/// `eventDate`, `authorName`; hedef ders (targetCourseId) etiketi [targetLabel]
/// ile gösterilir. Acil dışındaki duyurularda **"Takvime Ekle"** butonu bulunur.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.title,
    required this.content,
    required this.type,
    required this.eventDate,
    this.authorName = 'Akademi Yönetimi',
    this.targetLabel,
    this.onAddToCalendar,
    this.onTap,
  });

  final String title;
  final String content;
  final AnnouncementType type;
  final DateTime eventDate;
  final String authorName;

  /// Belirli bir derse hedeflenmiş duyurular için ders adı (null → tüm kampüs).
  final String? targetLabel;
  final VoidCallback? onAddToCalendar;
  final VoidCallback? onTap;

  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCrisis = type == AnnouncementType.urgent;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.radius16,
        side: BorderSide(
          color: isCrisis ? AppColors.criticalAbsenceRed : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isCrisis ? 1.5 : 1.0,
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
                  Flexible(child: AnnouncementTypeBadge(type: type)),
                  const SizedBox(width: AppDimensions.p8),
                  const Spacer(),
                  Icon(Icons.event_outlined, size: 14, color: muted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      formatDate(eventDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.p12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCrisis ? AppColors.criticalAbsenceRed : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.p6),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (targetLabel != null && targetLabel!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.p8),
                Row(
                  children: [
                    Icon(Icons.track_changes_rounded, size: 14, color: primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        targetLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppDimensions.p12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: primary.withValues(alpha: 0.2),
                    child: Text(
                      authorName.isNotEmpty ? authorName.characters.first.toUpperCase() : 'Y',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: muted),
                    ),
                  ),
                  if (onAddToCalendar != null && !isCrisis) ...[
                    const SizedBox(width: AppDimensions.p8),
                    _AddToCalendarButton(onPressed: onAddToCalendar!, color: primary),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renkli duyuru türü rozeti (Seminer, Hackathon, Resmi Tatil, Anlık Kriz).
class AnnouncementTypeBadge extends StatelessWidget {
  const AnnouncementTypeBadge({super.key, required this.type});

  final AnnouncementType type;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.forAnnouncementType(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: AppDimensions.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(announcementTypeIcon(type), size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              AppStrings.announcementType(type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToCalendarButton extends StatelessWidget {
  const _AddToCalendarButton({required this.onPressed, required this.color});

  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppDimensions.radiusFull,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppDimensions.radiusFull),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                'Takvime Ekle',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
