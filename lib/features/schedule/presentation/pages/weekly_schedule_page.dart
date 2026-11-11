import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../../../core/widgets/atmosphere/campus_scene.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../domain/entities/course_schedule_entity.dart';
import '../cubit/schedule_cubit.dart';
import '../cubit/schedule_state.dart';
import '../widgets/course_schedule_card.dart';
import '../widgets/course_visuals.dart';
import '../widgets/day_selector_tabs.dart';
import '../widgets/instructor_course_editor_modal.dart';

/// [WeeklySchedulePage] Modül 1.1: gün seçmeli haftalık ders programı.
/// Eğitmen ders ekleyebilir, düzenleyebilir ve silebilir.
class WeeklySchedulePage extends StatelessWidget {
  const WeeklySchedulePage({super.key});

  /// Yeni ders ekleme ([course] null) veya düzenleme modalını açar.
  static Future<void> openEditor(BuildContext context, {CourseScheduleEntity? course}) {
    final user = context.currentUser;
    final cubit = context.read<ScheduleCubit>();
    return InstructorCourseEditorModal.show(
      context,
      initialCourseId: course?.id,
      initialCourseCode: course?.courseCode,
      initialCourseName: course?.courseName,
      initialInstructorName: course?.instructorName ?? user.fullName,
      initialRoom: course?.roomLocation,
      initialDayOfWeek: course?.dayOfWeek ?? cubit.state.selectedDay,
      initialStartTime: course?.startTime,
      initialEndTime: course?.endTime,
      onSave:
          ({
            courseId,
            required courseCode,
            required courseName,
            required instructorName,
            required roomLocation,
            required dayOfWeek,
            required startTime,
            required endTime,
          }) async {
            final entity = CourseScheduleEntity(
              id: courseId ?? '',
              courseCode: courseCode.trim().toUpperCase(),
              courseName: courseName.trim(),
              instructorUid: course?.instructorUid ?? user.uid,
              instructorName: instructorName.trim(),
              roomLocation: roomLocation.trim(),
              dayOfWeek: dayOfWeek,
              startTime: startTime.trim(),
              endTime: endTime.trim(),
              credit: course?.credit ?? 4,
              totalHours: course?.totalHours ?? 40,
            );
            await cubit.saveCourse(actorRole: user.role, course: entity);
          },
    );
  }

  Future<void> _confirmDelete(BuildContext context, CourseScheduleEntity course) async {
    final cubit = context.read<ScheduleCubit>();
    final user = context.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dersi sil'),
        content: Text(
          '${course.courseCode} ${course.courseName} (${DateTimeHelper.dayName(course.dayOfWeek)} '
          '${course.timeRange}) programdan kaldırılsın mı?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.criticalAbsenceRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await cubit.deleteCourse(actorRole: user.role, courseId: course.id);
      messenger.showSnackBar(SnackBar(content: Text('${course.courseCode} programdan kaldırıldı.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(Failure.from(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;

    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        switch (state.status) {
          case ViewStatus.initial:
          case ViewStatus.loading:
            return const LoadingStateView();
          case ViewStatus.failure:
            return ErrorStateView(message: state.errorMessage, onRetry: context.read<ScheduleCubit>().start);
          case ViewStatus.loaded:
            break;
        }

        final dayCourses = state.selectedDayCourses;
        final next = state.nextCourse();
        final hasWeekend = state.courses.any((c) => c.dayOfWeek > 5) || state.selectedDay > 5;
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.only(top: AppDimensions.p8, bottom: 96),
          children: [
            DaySelectorTabs(
              selectedDayIndex: state.selectedDay,
              includeWeekend: hasWeekend,
              onDaySelected: context.read<ScheduleCubit>().selectDay,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.p20, AppDimensions.p8, AppDimensions.p20, 0),
              child: Text(
                '${DateTimeHelper.dayName(state.selectedDay)} • ${dayCourses.length} ders',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AppDimensions.p4),
            if (dayCourses.isEmpty)
              SizedBox(
                height: 260,
                child: EmptyStateView(
                  icon: Icons.event_available_outlined,
                  title: 'Bu gün ders yok',
                  message: user.isInstructor
                      ? 'Programa yeni bir ders ekleyebilirsiniz.'
                      : 'Seçili günde planlanmış bir dersin bulunmuyor.',
                  actionLabel: user.isInstructor ? 'Ders Ekle' : null,
                  onAction: user.isInstructor ? () => openEditor(context) : null,
                ),
              )
            else
              for (final course in dayCourses)
                CourseScheduleCard(
                  courseCode: course.courseCode,
                  courseName: course.courseName,
                  instructorName: course.instructorName,
                  roomLocation: course.roomLocation,
                  startTime: course.startTime,
                  endTime: course.endTime,
                  icon: CourseVisuals.iconFor(course.courseCode),
                  iconBgColor: CourseVisuals.colorFor(course.courseCode),
                  nextClassTime: next?.id == course.id ? course.nextStart() : null,
                  isHighlighted: course.isOngoing() || next?.id == course.id,
                  isInstructor: user.isInstructor,
                  onEdit: user.isInstructor ? () => openEditor(context, course: course) : null,
                  onDelete: user.isInstructor ? () => _confirmDelete(context, course) : null,
                ),
            const SizedBox(height: AppDimensions.p12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.p16),
              child: SizedBox(height: 150, child: CampusScene(borderRadius: AppDimensions.radius24)),
            ),
          ],
        );
      },
    );
  }
}
