import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../../../core/widgets/dashboard/instructor_dashboard_hero.dart';
import '../../../../core/widgets/dashboard/student_dashboard_hero.dart';
import '../../../../core/widgets/edu_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../assignments/presentation/cubit/assignment_cubit.dart';
import '../../../attendance/presentation/cubit/absence_control_cubit.dart';
import '../../../attendance/presentation/cubit/live_attendance_cubit.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../../forum/presentation/cubit/forum_cubit.dart';
import '../../../grades/presentation/cubit/grades_cubit.dart';
import '../../../schedule/presentation/cubit/schedule_cubit.dart';
import '../../../schedule/presentation/widgets/course_schedule_card.dart';
import '../../../schedule/presentation/widgets/course_visuals.dart';
import '../../domain/entities/announcement_entity.dart';
import '../cubit/announcement_cubit.dart';
import '../cubit/announcement_state.dart';
import '../widgets/announcement_card.dart';
import '../widgets/create_announcement_sheet.dart';
import '../widgets/crisis_broadcast_bottom_sheet.dart';
import '../widgets/interactive_event_calendar.dart';

/// [HomeAnnouncementsPage] rol bazlı ana sayfa: öğrenci / eğitmen paneli,
/// etkinlik takvimi ve kampüs duyuruları.
class HomeAnnouncementsPage extends StatelessWidget {
  const HomeAnnouncementsPage({super.key, required this.onNavigateTab});

  /// Alt menü sekmesine geçiş (0 Ana Sayfa … 4 Profil/Analiz).
  final ValueChanged<int> onNavigateTab;

  static List<String> _targets(BuildContext context) => [
    AnnouncementEntity.generalTarget,
    ...context.read<ScheduleCubit>().state.courseNames,
  ];

  static Future<void> openCrisisBroadcast(BuildContext context) {
    final user = context.currentUser;
    final cubit = context.read<AnnouncementCubit>();
    return CrisisBroadcastBottomSheet.show(
      context,
      targets: {for (final t in _targets(context)) t: t},
      onBroadcast: ({required targetId, required targetLabel, required title, required message}) =>
          cubit.broadcastCrisis(actor: user, title: title, message: message, targetCourse: targetId),
    );
  }

  static Future<void> openCreateAnnouncement(BuildContext context) {
    final user = context.currentUser;
    final cubit = context.read<AnnouncementCubit>();
    final messenger = ScaffoldMessenger.of(context);
    return CreateAnnouncementSheet.show(
      context,
      targets: _targets(context),
      onCreate: ({required title, required content, required type, required eventDate, required targetCourse}) async {
        await cubit.createAnnouncement(
          actor: user,
          title: title,
          content: content,
          type: type,
          eventDate: eventDate,
          targetCourse: targetCourse,
        );
        messenger.showSnackBar(const SnackBar(content: Text('Duyuru yayınlandı ve öğrencilere bildirildi.')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;

    return ListView(
      // Hero sahnesi tam genişlik ve şeffaf AppBar'ın hemen altından başlar.
      padding: const EdgeInsets.only(bottom: AppDimensions.p32),
      children: [
        if (user.isStudent) _StudentHero(user: user, onNavigateTab: onNavigateTab),
        if (user.isInstructor) ...[
          _InstructorHero(user: user, onNavigateTab: onNavigateTab),
          _TodaysCourses(onNavigateTab: onNavigateTab),
        ],
        const SizedBox(height: AppDimensions.p16),
        const _AnnouncementsSection(),
      ],
    );
  }
}

class _StudentHero extends StatelessWidget {
  const _StudentHero({required this.user, required this.onNavigateTab});

  final UserEntity user;
  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleCubit>().state;
    final absence = context.watch<AbsenceControlCubit>().state;
    final assignments = context.watch<AssignmentCubit>().state;
    final grades = context.watch<GradesCubit>().state;
    final live = context.watch<LiveAttendanceCubit>().state;

    final next = schedule.nextCourse();
    final ongoing = schedule.ongoingCourse();
    final shown = ongoing ?? next;
    final openCount = assignments.openAssignmentsFor(user.uid).length;
    final overdue = assignments.hasOverdueFor(user.uid);
    final critical = absence.criticalFor(user.uid);
    final gpa = grades.gpaFor(user.uid);

    final String bannerTitle;
    final String bannerSubtitle;
    VoidCallback? bannerTap;
    if (critical.isNotEmpty) {
      bannerTitle = 'Devamsızlık sınırındasın ⚠️';
      bannerSubtitle = '${critical.length} derste %20 sınırını aştın. Detaylar için dokun.';
      bannerTap = () => Navigator.of(context).pushNamed(RouteNames.absenceControl);
    } else if (overdue) {
      bannerTitle = 'Geciken ödevin var ⏰';
      bannerSubtitle = 'Geç teslimde 10 puan ceza uygulanır, hemen yükle.';
      bannerTap = () => onNavigateTab(2);
    } else {
      bannerTitle = 'Harika ilerliyorsun! 🎉';
      bannerSubtitle = 'Bu dönem GPA\'n ${gpa.termGpa.toStringAsFixed(2)} • $openCount açık ödev.';
      bannerTap = () => onNavigateTab(4);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentDashboardHero(
          studentName: user.greetingName,
          nextCourseName: shown?.courseName ?? 'Planlanmış ders yok',
          nextCourseTimeAndRoom: shown == null
              ? 'Ders programın boş'
              : '${ongoing != null ? 'Şu an • ' : '${DateTimeHelper.dayName(shown.dayOfWeek)} '}'
                    '${shown.timeRange} • ${shown.roomLocation}',
          nextCourseStartTime: next?.nextStart(),
          nextCourseIcon: CourseVisuals.iconFor(shown?.courseCode ?? ''),
          attendanceRate: '%${absence.attendanceRateFor(user.uid).round()}',
          activeAssignments: '$openCount',
          gpa: gpa.cumulativeGpa.toStringAsFixed(2),
          bannerTitle: bannerTitle,
          bannerSubtitle: bannerSubtitle,
          onBannerTap: bannerTap,
          onNextCourseTap: () => onNavigateTab(1),
          onAttendanceTap: () => Navigator.of(context).pushNamed(RouteNames.absenceControl),
          onAssignmentsTap: () => onNavigateTab(2),
          onGpaTap: () => onNavigateTab(4),
        ),
        if (live.activeSessions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.p16, AppDimensions.p12, AppDimensions.p16, 0),
            child: EduCard(
              highlighted: true,
              glowColor: AppColors.secondaryLight,
              onTap: () => Navigator.of(context).pushNamed(RouteNames.liveAttendance),
              child: Row(
                children: [
                  const Icon(Icons.sensors_rounded, color: AppColors.secondaryLight),
                  const SizedBox(width: AppDimensions.p12),
                  Expanded(
                    child: Text(
                      'Canlı yoklama açık: ${live.activeSessions.map((s) => s.courseCode).join(', ')}\n'
                      'PIN kodunu girerek derse katıl.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InstructorHero extends StatelessWidget {
  const _InstructorHero({required this.user, required this.onNavigateTab});

  final UserEntity user;
  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final assignments = context.watch<AssignmentCubit>().state;
    final grades = context.watch<GradesCubit>().state;
    final forum = context.watch<ForumCubit>().state;

    return InstructorDashboardHero(
      instructorName: user.fullName,
      pendingHomeworksCount: assignments.pendingGradingCount,
      classSuccessRate: '%${grades.overallPassRate.round()}',
      newQuestionsCount: forum.unresolvedCount,
      onStartAttendance: () => Navigator.of(context).pushNamed(RouteNames.liveAttendance),
      onPendingHomeworksTap: () => onNavigateTab(2),
      onClassAnalysisTap: () => onNavigateTab(4),
      onSendAnnouncementTap: () => HomeAnnouncementsPage.openCrisisBroadcast(context),
      onQuestionsTap: () => onNavigateTab(3),
    );
  }
}

class _TodaysCourses extends StatelessWidget {
  const _TodaysCourses({required this.onNavigateTab});

  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleCubit>().state;
    final today = schedule.todaysCourses();
    final next = schedule.nextCourse();
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimensions.p8),
        SectionHeader(
          title: AppStrings.todaysCourses,
          actionLabel: AppStrings.viewAll,
          onAction: () => onNavigateTab(1),
        ),
        if (today.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p20, vertical: AppDimensions.p8),
            child: Text('Bugün planlanmış dersiniz yok.', style: TextStyle(color: muted)),
          )
        else
          for (final c in today)
            CourseScheduleCard(
              courseCode: c.courseCode,
              courseName: c.courseName,
              instructorName: c.instructorName,
              roomLocation: c.roomLocation,
              startTime: c.startTime,
              endTime: c.endTime,
              icon: CourseVisuals.iconFor(c.courseCode),
              iconBgColor: CourseVisuals.colorFor(c.courseCode),
              nextClassTime: next?.id == c.id ? c.nextStart() : null,
              isHighlighted: c.isOngoing() || next?.id == c.id,
              onTap: () => onNavigateTab(1),
            ),
      ],
    );
  }
}

class _AnnouncementsSection extends StatelessWidget {
  const _AnnouncementsSection();

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return BlocBuilder<AnnouncementCubit, AnnouncementState>(
      builder: (context, state) {
        final cubit = context.read<AnnouncementCubit>();
        if (state.status == ViewStatus.loading || state.status == ViewStatus.initial) {
          return const SizedBox(height: 160, child: LoadingStateView());
        }
        final items = state.visibleAnnouncements;
        final selected = state.selectedDate;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InteractiveEventCalendar(
              selectedDate: selected ?? DateTime.now(),
              onDateSelected: cubit.selectDate,
              eventDates: state.eventDates,
            ),
            const SizedBox(height: AppDimensions.p8),
            SectionHeader(
              title: selected == null ? 'Güncel Duyurular' : '${DateTimeHelper.formatDate(selected)} Etkinlikleri',
              actionLabel: selected != null ? AppStrings.viewAll : (user.isInstructor ? 'Yeni Duyuru' : null),
              onAction: selected != null
                  ? cubit.clearDateFilter
                  : (user.isInstructor ? () => HomeAnnouncementsPage.openCreateAnnouncement(context) : null),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p20, vertical: AppDimensions.p16),
                child: Text(
                  selected == null ? 'Henüz duyuru yok.' : 'Bu tarihte planlanmış etkinlik yok.',
                  style: TextStyle(color: muted),
                ),
              )
            else
              for (final a in items)
                AnnouncementCard(
                  title: a.title,
                  content: a.content,
                  targetLabel: a.targetCourse == AnnouncementEntity.generalTarget ? null : a.targetCourse,
                  type: a.type,
                  eventDate: a.eventDate,
                  authorName: a.authorName,
                  onAddToCalendar: () {
                    cubit.focusDate(a.eventDate);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${DateTimeHelper.formatDate(a.eventDate)} takvimde işaretlendi.')),
                    );
                  },
                ),
          ],
        );
      },
    );
  }
}
