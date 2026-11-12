import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../enums/user_role.dart';
import '../animations/fade_slide_in.dart';
import '../edu_card.dart';
import 'metric_badge_card.dart';
import 'next_class_highlight_card.dart';
import 'portal_avatar.dart';
import 'portal_hero_header.dart';

/// [StudentDashboardHero] Öğrenci Portalı Ana Sayfa üst bölümü (mockup birebir):
/// 1. Kampüs sahnesi üstünde "Merhaba, {isim}! 👋" + karakter avatarı
/// 2. Sahnenin üstüne binen "Sıradaki Ders" kartı ve geri sayım şeridi
/// 3. Üç pastel metrik kutusu (%92 Katılım, 3 Aktif Ödev, 3.42 GPA)
/// 4. Haftalık motivasyon bandı
///
/// Liste içinde **üst padding olmadan** kullanılmalıdır; sahne tam genişliktir.
class StudentDashboardHero extends StatelessWidget {
  const StudentDashboardHero({
    super.key,
    this.studentName = 'Ayberk',
    this.nextCourseName = 'Flutter ile Mobil Geliştirme',
    this.nextCourseTimeAndRoom = '10:30 - 12:00 • A204',
    this.nextCourseStartTime,
    this.nextCourseIcon = Icons.flutter_dash_rounded,
    this.attendanceRate = '%92',
    this.activeAssignments = '3',
    this.gpa = '3.42',
    this.avatarAsset,
    this.bannerTitle = 'Harika ilerliyorsun! 🎉',
    this.bannerSubtitle = 'Bu hafta 4 dersini tamamladın.',
    this.onNextCourseTap,
    this.onAttendanceTap,
    this.onAssignmentsTap,
    this.onGpaTap,
    this.onBannerTap,
  });

  final String studentName;
  final String nextCourseName;
  final String nextCourseTimeAndRoom;
  final DateTime? nextCourseStartTime;
  final IconData nextCourseIcon;
  final String attendanceRate;
  final String activeAssignments;
  final String gpa;
  final String? avatarAsset;
  final String bannerTitle;
  final String bannerSubtitle;
  final VoidCallback? onNextCourseTap;
  final VoidCallback? onAttendanceTap;
  final VoidCallback? onAssignmentsTap;
  final VoidCallback? onGpaTap;
  final VoidCallback? onBannerTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortalHeroHeader(
          greeting: 'Merhaba,',
          name: '$studentName! 👋',
          subtitle: AppStrings.studentGreetingSubtitle,
          avatar: PortalAvatar(role: UserRole.student, imageAsset: avatarAsset),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Açılış: kartlar yukarıdan aşağıya sırayla akarak gelir.
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: NextClassHighlightCard(
                  courseName: nextCourseName,
                  timeAndRoom: nextCourseTimeAndRoom,
                  startTime: nextCourseStartTime ?? DateTime.now().add(const Duration(minutes: 45)),
                  courseIcon: nextCourseIcon,
                  onTap: onNextCourseTap,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 360),
                      beginScale: 0.92,
                      child: MetricBadgeCard(
                        value: attendanceRate,
                        label: AppStrings.attendanceRate,
                        icon: Icons.check_rounded,
                        accentColor: AppColors.secondaryLight,
                        tileColor: AppColors.tileGreenLight,
                        onTap: onAttendanceTap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 420),
                      beginScale: 0.92,
                      child: MetricBadgeCard(
                        value: activeAssignments,
                        label: AppStrings.activeAssignments,
                        icon: Icons.menu_book_rounded,
                        accentColor: AppColors.metricPurple,
                        tileColor: AppColors.tilePurpleLight,
                        onTap: onAssignmentsTap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 480),
                      beginScale: 0.92,
                      child: MetricBadgeCard(
                        value: gpa,
                        label: 'GPA',
                        icon: Icons.auto_awesome_rounded,
                        accentColor: AppColors.metricPink,
                        tileColor: AppColors.tilePinkLight,
                        onTap: onGpaTap,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 560),
                child: _AchievementBanner(title: bannerTitle, subtitle: bannerSubtitle, onTap: onBannerTap),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementBanner extends StatelessWidget {
  const _AchievementBanner({required this.title, required this.subtitle, this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return EduCard(
      glowColor: AppColors.accentLight,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      borderRadius: AppDimensions.radius20,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentLight.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text('🏆', style: TextStyle(fontSize: 20, height: 1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: muted),
        ],
      ),
    );
  }
}
