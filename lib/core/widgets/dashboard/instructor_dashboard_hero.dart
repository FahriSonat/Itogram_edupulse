import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../enums/user_role.dart';
import '../animations/fade_slide_in.dart';
import '../edu_card.dart';
import 'portal_avatar.dart';
import 'portal_hero_header.dart';

/// [InstructorDashboardHero] Eğitmen Yönetim Paneli Ana Sayfa üst bölümü (mockup birebir):
/// 1. Kampüs sahnesi üstünde "Merhaba, {isim}!" + karakter avatarı
/// 2. "Yoklamayı Başlat" gradyan CTA (Aydınlık: indigo→mor, Karanlık: elektrik mavisi)
/// 3. 2x2 operasyon kartı (Ödevler, Sınıf Analizi, Duyuru Gönder, Sorular)
///
/// Liste içinde **üst padding olmadan** kullanılmalıdır; sahne tam genişliktir.
class InstructorDashboardHero extends StatelessWidget {
  const InstructorDashboardHero({
    super.key,
    this.instructorName = 'Mustafa Hoca',
    required this.onStartAttendance,
    required this.onPendingHomeworksTap,
    required this.onClassAnalysisTap,
    required this.onSendAnnouncementTap,
    required this.onQuestionsTap,
    this.pendingHomeworksCount = 12,
    this.classSuccessRate = '%86',
    this.newQuestionsCount = 5,
    this.avatarAsset,
  });

  final String instructorName;
  final VoidCallback onStartAttendance;
  final VoidCallback onPendingHomeworksTap;
  final VoidCallback onClassAnalysisTap;
  final VoidCallback onSendAnnouncementTap;
  final VoidCallback onQuestionsTap;
  final int pendingHomeworksCount;
  final String classSuccessRate;
  final int newQuestionsCount;
  final String? avatarAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortalHeroHeader(
          greeting: 'Merhaba,',
          name: '$instructorName! 👋',
          subtitle: AppStrings.instructorGreetingSubtitle,
          avatar: PortalAvatar(role: UserRole.instructor, imageAsset: avatarAsset),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Açılış: CTA ve operasyon kartları sırayla akarak gelir.
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: _AttendanceCta(onTap: onStartAttendance),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _stagger(
                      0,
                      _OperationCard(
                        title: AppStrings.pendingHomeworks,
                        subtitle: '$pendingHomeworksCount Bekleyen',
                        icon: Icons.assignment_rounded,
                        color: AppColors.accentLight,
                        onTap: onPendingHomeworksTap,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.p12),
                  Expanded(
                    child: _stagger(
                      1,
                      _OperationCard(
                        title: AppStrings.classAnalysis,
                        subtitle: '$classSuccessRate Başarı',
                        icon: Icons.bar_chart_rounded,
                        color: AppColors.secondaryLight,
                        onTap: onClassAnalysisTap,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.p12),
              Row(
                children: [
                  Expanded(
                    child: _stagger(
                      2,
                      _OperationCard(
                        title: AppStrings.sendAnnouncement,
                        subtitle: 'Tüm sınıfa',
                        icon: Icons.campaign_rounded,
                        color: AppColors.metricPurple,
                        onTap: onSendAnnouncementTap,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.p12),
                  Expanded(
                    child: _stagger(
                      3,
                      _OperationCard(
                        title: AppStrings.campusQuestions,
                        subtitle: '$newQuestionsCount Yeni Soru',
                        icon: Icons.help_rounded,
                        color: AppColors.primaryDark,
                        onTap: onQuestionsTap,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _stagger(int index, Widget child) => FadeSlideIn(
    delay: Duration(milliseconds: 360 + index * 60),
    beginScale: 0.94,
    child: child,
  );
}

class _AttendanceCta extends StatelessWidget {
  const _AttendanceCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return EduCard(
      gradient: isDark ? AppColors.nextClassDarkGradient : AppColors.attendanceCtaLightGradient,
      highlighted: true,
      borderRadius: AppDimensions.radius24,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.startAttendance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppStrings.qrPinSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: AppDimensions.radiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '60 sn geçerli kod',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: AppDimensions.radius16,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, size: 30, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return EduCard(
      glowColor: color,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      borderRadius: AppDimensions.radius20,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.22 : 0.14),
              borderRadius: AppDimensions.radius12,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dar telefonlarda "Duyuru Gönder" kesilmesin: gerekirse hafifçe küçülür.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
