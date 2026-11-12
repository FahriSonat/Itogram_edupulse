import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/countdown_timer_widget.dart';
import '../../../../core/widgets/edu_card.dart';

/// [CourseScheduleCard] ders programı kartıdır: gradyan ikon karosu, saat, amfi rozeti (ör. D-107),
/// hoca adı ve isteğe bağlı canlı geri sayım rozeti.
///
/// [isHighlighted] (sıradaki ders) → Aydınlık: şeftali zemin, Karanlık: mavi hale.
class CourseScheduleCard extends StatelessWidget {
  const CourseScheduleCard({
    super.key,
    required this.courseCode,
    required this.courseName,
    required this.instructorName,
    required this.roomLocation,
    required this.startTime,
    required this.endTime,
    this.icon = Icons.code_rounded,
    this.iconBgColor,
    this.nextClassTime,
    this.isInstructor = false,
    this.isHighlighted = false,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  final String courseCode;
  final String courseName;
  final String instructorName;

  /// Örn: A204, D-107
  final String roomLocation;

  /// Örn: 10:30
  final String startTime;

  /// Örn: 12:00
  final String endTime;
  final IconData icon;
  final Color? iconBgColor;
  final DateTime? nextClassTime;
  final bool isInstructor;
  final bool isHighlighted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final tileColor = iconBgColor ?? primaryColor;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return EduCard(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      tint: isHighlighted ? const Color(0xFFFFF3E8) : null,
      glowColor: isHighlighted ? AppColors.glowBlue : null,
      highlighted: isHighlighted,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(tileColor, Colors.white, 0.15)!, tileColor],
                  ),
                  borderRadius: AppDimensions.radius12,
                  boxShadow: [
                    BoxShadow(color: tileColor.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: AppDimensions.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: muted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '$startTime - $endTime',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: muted),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.p8),
                        Flexible(
                          child: _RoomChip(room: roomLocation, color: primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isInstructor) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Düzenle',
                  color: primaryColor,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Sil',
                  color: AppColors.criticalAbsenceRed,
                  visualDensity: VisualDensity.compact,
                ),
              ] else
                Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  instructorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: muted),
                ),
              ),
              if (nextClassTime != null) ...[
                const SizedBox(width: AppDimensions.p8),
                // Sayaç en fazla satırın yarısını kaplar; metni gerekirse kısaltılır.
                Flexible(child: CountdownTimerWidget(targetDateTime: nextClassTime, isCompact: true)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Sınıf / amfi konumu rozeti (ör. `D-107`).
class _RoomChip extends StatelessWidget {
  const _RoomChip({required this.room, required this.color});

  final String room;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sınıf / Amfi: $room',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppDimensions.radiusFull),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 12, color: color),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  room,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
