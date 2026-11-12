import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/attendance_status.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/widgets/role_visibility_guard.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../../schedule/presentation/widgets/course_dropdown.dart';
import '../../domain/entities/student_absence_record_entity.dart';
import '../cubit/absence_control_cubit.dart';
import '../cubit/absence_control_state.dart';
import '../widgets/bell_curve_chart_painter.dart';
import '../widgets/critical_absence_red_list.dart';
import '../widgets/student_absence_progress_card.dart';

/// 2.4 DEVAMSIZLIK KONTROL: öğrenci ders bazlı saat / yüzde devamsızlığını
/// görür; eğitmen sınıfın çan eğrisini, %20 kırmızı listesini ve yoklama
/// ekleme / değiştirme kontrollerini görür.
class AbsenceControlPage extends StatelessWidget {
  const AbsenceControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    final role = context.currentRole;
    return BlocProvider<AbsenceControlCubit>(
      create: (_) {
        final cubit = GetIt.instance<AbsenceControlCubit>();
        return role.isInstructor
            ? (cubit..loadForInstructor())
            : (cubit..loadForStudent(user?.uid ?? ''));
      },
      child: RoleVisibilityGuard(
        currentRole: role,
        studentBuilder: (_) => const _StudentAbsenceView(),
        instructorBuilder: (_) => const _InstructorAbsenceView(),
      ),
    );
  }
}

Widget _stateShield(BuildContext context, AbsenceControlState state, VoidCallback onRetry, Widget Function() loaded) {
  if (state.status.isLoading && state.records.isEmpty) return const LoadingStateView(message: 'Devamsızlık verileri yükleniyor...');
  if (state.status == ViewStatus.failure) return ErrorStateView(message: state.errorMessage, onRetry: onRetry);
  return loaded();
}

// =========================================================================
// Öğrenci
// =========================================================================

class _StudentAbsenceView extends StatelessWidget {
  const _StudentAbsenceView();

  @override
  Widget build(BuildContext context) {
    final uid = context.currentUser?.uid ?? '';
    return BlocBuilder<AbsenceControlCubit, AbsenceControlState>(
      builder: (context, state) => _stateShield(
        context,
        state,
        () => context.read<AbsenceControlCubit>().loadForStudent(uid),
        () {
          if (state.records.isEmpty) {
            return const EmptyStateView(
              title: 'Devamsızlık kaydı yok',
              message: 'Derslere ait yoklama kaydın henüz oluşmadı.',
              icon: Icons.event_available_rounded,
            );
          }
          final critical = state.records.where((r) => r.isCriticalRisk).toList();
          return ListView(
            padding: AppDimensions.paddingAll16,
            children: [
              if (critical.isNotEmpty) ...[
                _CriticalBanner(courseNames: critical.map((r) => r.courseName).toList()),
                const SizedBox(height: AppDimensions.p16),
              ],
              for (final r in state.records) ...[
                StudentAbsenceProgressCard(
                  courseName: r.courseName,
                  totalCourseHours: r.totalCourseHours,
                  absentHours: r.absentHours,
                ),
                const SizedBox(height: AppDimensions.p12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CriticalBanner extends StatelessWidget {
  const _CriticalBanner({required this.courseNames});

  final List<String> courseNames;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppDimensions.paddingAll16,
      decoration: BoxDecoration(
        color: AppColors.criticalAbsenceRed.withValues(alpha: 0.1),
        borderRadius: AppDimensions.radius16,
        border: Border.all(color: AppColors.criticalAbsenceRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.criticalAbsenceRed),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Text(
              'Kritik Risk: ${courseNames.join(', ')} dersinde devamsızlığın %20 sınırını aştı.',
              style: const TextStyle(color: AppColors.criticalAbsenceRed, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Eğitmen
// =========================================================================

class _InstructorAbsenceView extends StatelessWidget {
  const _InstructorAbsenceView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AbsenceControlCubit, AbsenceControlState>(
      listenWhen: (p, c) => c.actionMessage != null && p.actionMessage != c.actionMessage,
      listener: (context, state) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.actionMessage!))),
      builder: (context, state) {
        final cubit = context.read<AbsenceControlCubit>();
        if (state.status != ViewStatus.failure && state.courses.isEmpty && !state.status.isLoading) {
          return const EmptyStateView(
            title: 'Ders bulunamadı',
            message: 'Önce Ders Programı\'na ders ekleyin.',
            icon: Icons.event_busy_rounded,
          );
        }
        return ListView(
          padding: AppDimensions.paddingAll16,
          children: [
            if (state.courses.isNotEmpty)
              CourseDropdown(
                courses: state.courses,
                selectedCourseId: state.selectedCourseId,
                onChanged: cubit.selectCourse,
              ),
            const SizedBox(height: AppDimensions.p16),
            _stateShield(context, state, cubit.loadForInstructor, () {
              final d = state.distribution;
              final courseName = state.courses
                  .where((c) => c.courseId == state.selectedCourseId)
                  .map((c) => c.courseName)
                  .firstOrNull;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BellCurveChartWidget(
                    midtermAverage: d.midtermAverage,
                    finalAverage: d.finalAverage,
                    midtermStandardDeviation: d.midtermStd,
                    finalStandardDeviation: d.finalStd,
                    sampleSize: d.sampleSize,
                  ),
                  const SizedBox(height: AppDimensions.p16),
                  CriticalAbsenceRedList(
                    atRiskStudents: [
                      for (final r in state.criticalRecords)
                        CriticalAbsenceItem(
                          studentUid: r.studentUid,
                          studentName: r.studentName,
                          studentNo: r.studentNo,
                          courseId: r.courseId,
                          courseName: r.courseName.isEmpty ? (courseName ?? '') : r.courseName,
                          absentHours: r.absentHours,
                          totalCourseHours: r.totalCourseHours,
                          absencePercentage: r.absencePercentage,
                          isCriticalRisk: true,
                        ),
                    ],
                    onSendPushWarning: (s) => cubit.sendRiskWarning(s.studentUid),
                  ),
                  const SizedBox(height: AppDimensions.p8),
                  const SectionHeader(title: 'Sınıf Yoklama Kayıtları', padding: EdgeInsets.symmetric(vertical: 8)),
                  if (state.records.isEmpty)
                    const Padding(
                      padding: AppDimensions.paddingAll16,
                      child: Text('Bu derse kayıtlı öğrenci yoklama kaydı yok.'),
                    )
                  else
                    for (final r in state.records) _StudentRow(record: r),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.record});

  final StudentAbsenceRecordEntity record;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AbsenceControlCubit>();
    final critical = record.isCriticalRisk || record.absencePercentage >= 20;
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.p8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (critical ? AppColors.criticalAbsenceRed : AppColors.resolvedGreen).withValues(alpha: 0.15),
          child: Icon(
            critical ? Icons.priority_high_rounded : Icons.person_rounded,
            color: critical ? AppColors.criticalAbsenceRed : AppColors.resolvedGreen,
          ),
        ),
        title: Text(record.studentName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${record.studentNo} · ${record.absentHours}/${record.totalCourseHours} saat · %${record.absencePercentage.toStringAsFixed(1)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<AttendanceStatus>(
          tooltip: 'Yoklama ekle / değiştir',
          icon: const Icon(Icons.edit_calendar_rounded),
          onSelected: (status) => cubit.markAttendance(record.studentUid, status),
          itemBuilder: (_) => const [
            PopupMenuItem(value: AttendanceStatus.present, child: Text('Geldi olarak işaretle')),
            PopupMenuItem(value: AttendanceStatus.absent, child: Text('Devamsızlık ekle')),
            PopupMenuItem(value: AttendanceStatus.excused, child: Text('İzinli olarak işaretle')),
          ],
        ),
      ),
    );
  }
}
