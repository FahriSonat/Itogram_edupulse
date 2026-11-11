import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/widgets/role_visibility_guard.dart';
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

/// 2.1 DERS PROGRAMI: öğrenci haftalık derslerini ve derse kalan süreyi görür;
/// eğitmen ek olarak her kartta Düzenle / Sil ve "Yeni Ders Ekle" butonunu görür.
class WeeklySchedulePage extends StatelessWidget {
  const WeeklySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScheduleCubit>(
      create: (_) => GetIt.instance<ScheduleCubit>()..start(),
      child: const _ScheduleView(),
    );
  }
}

class _ScheduleView extends StatelessWidget {
  const _ScheduleView();

  @override
  Widget build(BuildContext context) {
    final role = context.currentRole;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: RoleVisibilityGuard.onlyInstructor(
        currentRole: role,
        child: FloatingActionButton.extended(
          key: const Key('schedule_add_course'),
          onPressed: () => _openEditor(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yeni Ders Ekle'),
        ),
      ),
      body: BlocConsumer<ScheduleCubit, ScheduleState>(
        listenWhen: (p, c) => c.actionMessage != null && p.actionMessage != c.actionMessage,
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.actionMessage!))),
        builder: (context, state) {
          final cubit = context.read<ScheduleCubit>();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppDimensions.p16, AppDimensions.p12, AppDimensions.p16, 0),
                child: DaySelectorTabs(
                  selectedDayIndex: state.selectedDay,
                  onDaySelected: cubit.selectDay,
                  includeWeekend: state.courses.any((c) => c.dayOfWeek > 5),
                ),
              ),
              Expanded(child: _body(context, state, role)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, ScheduleState state, UserRole role) {
    final cubit = context.read<ScheduleCubit>();
    if (state.status.isLoading) return const LoadingStateView(message: 'Ders programı yükleniyor...');
    if (state.status == ViewStatus.failure) {
      return ErrorStateView(message: state.errorMessage, onRetry: cubit.start);
    }
    final courses = state.coursesOfSelectedDay;
    if (courses.isEmpty) {
      return EmptyStateView(
        title: 'Bu gün ders yok',
        message: role == UserRole.instructor ? '"Yeni Ders Ekle" ile programa ders ekleyebilirsin.' : 'Keyfini çıkar!',
        icon: Icons.free_breakfast_outlined,
      );
    }
    final next = cubit.nextCourse;
    final isInstructor = role == UserRole.instructor;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppDimensions.p16, AppDimensions.p16, AppDimensions.p16, 96),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.p12),
      itemBuilder: (context, i) {
        final c = courses[i];
        return CourseScheduleCard(
          key: ValueKey<String>('course_${c.courseId}'),
          courseCode: c.courseCode,
          courseName: c.courseName,
          instructorName: c.instructorName,
          roomLocation: c.roomLocation,
          startTime: c.startTime,
          endTime: c.endTime,
          icon: CourseVisuals.iconFor(c.courseCode),
          iconBgColor: CourseVisuals.colorFor(c.courseCode),
          nextClassTime: cubit.nextStartOf(c),
          isHighlighted: next?.courseId == c.courseId && next?.dayOfWeek == c.dayOfWeek,
          isInstructor: isInstructor,
          onEdit: isInstructor ? () => _openEditor(context, course: c) : null,
          onDelete: isInstructor ? () => _confirmDelete(context, c) : null,
        );
      },
    );
  }

  static Future<void> _openEditor(BuildContext context, {CourseScheduleEntity? course}) {
    final cubit = context.read<ScheduleCubit>();
    return InstructorCourseEditorModal.show(
      context,
      initialCourseId: course?.courseId,
      initialCourseCode: course?.courseCode,
      initialCourseName: course?.courseName,
      initialInstructorName: course?.instructorName ?? context.readCurrentUser()?.fullName,
      initialRoom: course?.roomLocation,
      initialDayOfWeek: course?.dayOfWeek ?? cubit.state.selectedDay,
      initialStartTime: course?.startTime,
      initialEndTime: course?.endTime,
      onSave: ({
        String? courseId,
        required String courseCode,
        required String courseName,
        required String instructorName,
        required String roomLocation,
        required int dayOfWeek,
        required String startTime,
        required String endTime,
      }) async {
        await cubit.saveCourse(
          courseId: courseId,
          courseCode: courseCode,
          courseName: courseName,
          instructorName: instructorName,
          roomLocation: roomLocation,
          dayOfWeek: dayOfWeek,
          startTime: startTime,
          endTime: endTime,
        );
      },
    );
  }

  static Future<void> _confirmDelete(BuildContext context, CourseScheduleEntity course) async {
    final cubit = context.read<ScheduleCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dersi sil'),
        content: Text('${course.courseCode} · ${course.courseName} programdan çıkarılsın mı?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok ?? false) await cubit.removeCourse(course.courseId);
  }
}
