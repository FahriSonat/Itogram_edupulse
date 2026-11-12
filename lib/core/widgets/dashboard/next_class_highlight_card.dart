import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../countdown_timer_widget.dart';
import '../edu_card.dart';

/// [NextClassHighlightCard] mockup'taki "Sıradaki Ders" kartıdır (Modül 1.1).
///
/// - Aydınlık: beyaz kart, turuncu "Sıradaki Ders" rozeti, şeftali geri sayım şeridi.
/// - Karanlık: mavi gradyan kart, cam efektli rozet ve koyu mavi geri sayım şeridi.
class NextClassHighlightCard extends StatelessWidget {
  const NextClassHighlightCard({
    super.key,
    required this.courseName,
    required this.timeAndRoom,
    required this.startTime,
    this.courseIcon = Icons.flutter_dash_rounded,
    this.onTap,
  });

  final String courseName;
  final String timeAndRoom;
  final DateTime startTime;
  final IconData courseIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onCard = isDark ? Colors.white : AppColors.textPrimaryLight;
    final onCardMuted = isDark ? Colors.white.withValues(alpha: 0.78) : AppColors.textSecondaryLight;

    return EduCard(
      gradient: isDark ? AppColors.nextClassDarkGradient : null,
      highlighted: true,
      borderRadius: AppDimensions.radius24,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pill(isDark: isDark),
                    const SizedBox(height: 10),
                    Text(
                      courseName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: onCard,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 15, color: onCardMuted),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            timeAndRoom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: onCardMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CourseIconTile(icon: courseIcon, isDark: isDark),
            ],
          ),
          const SizedBox(height: 14),
          CountdownTimerWidget(
            targetDateTime: startTime,
            customBuilder: (context, remaining, isExpired) =>
                _CountdownStrip(text: _format(remaining, isExpired), isDark: isDark),
          ),
        ],
      ),
    );
  }

  static String _format(Duration d, bool isExpired) {
    if (isExpired) return 'Ders başladı';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '$hours sa $minutes dk kaldı';
    if (minutes > 0) return '$minutes dakika kaldı';
    return '${d.inSeconds} saniye kaldı';
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.18) : AppColors.accentWarm,
        borderRadius: AppDimensions.radiusFull,
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.3)) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.accentWarm.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Text(
        AppStrings.nextCourse,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    );
  }
}

class _CourseIconTile extends StatelessWidget {
  const _CourseIconTile({required this.icon, required this.isDark});

  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.14) : AppColors.tileBlueLight,
        borderRadius: AppDimensions.radius16,
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.25) : Colors.white, width: 1.5),
      ),
      child: Icon(icon, size: 32, color: isDark ? Colors.white : AppColors.primaryLight),
    );
  }
}

class _CountdownStrip extends StatelessWidget {
  const _CountdownStrip({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1F5C).withValues(alpha: 0.45) : AppColors.accentWarmSoft,
        borderRadius: AppDimensions.radius16,
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.14)) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 20, color: isDark ? const Color(0xFFFCD34D) : AppColors.accentWarm),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimaryLight),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white : AppColors.accentWarm),
            child: Icon(Icons.arrow_forward_rounded, size: 18, color: isDark ? AppColors.primaryLight : Colors.white),
          ),
        ],
      ),
    );
  }
}
