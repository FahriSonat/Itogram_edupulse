import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/widgets/atmosphere/ambient_background.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/edu_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../domain/entities/student_absence_record_entity.dart';
import '../cubit/absence_control_cubit.dart';
import '../cubit/absence_control_state.dart';
import '../widgets/critical_absence_red_list.dart';
import '../widgets/student_absence_progress_card.dart';

/// [AbsenceControlPage] Modül 1.2 / 2.2 — Devamsızlık Kontrol (%20 Kalkanı).
class AbsenceControlPage extends StatelessWidget {
  const AbsenceControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(title: AppStrings.navAbsence, currentRole: user.role),
        body: BlocBuilder<AbsenceControlCubit, AbsenceControlState>(
          builder: (context, state) {
            switch (state.status) {
              case ViewStatus.initial:
              case ViewStatus.loading:
                return const LoadingStateView();
              case ViewStatus.failure:
                return ErrorStateView(message: state.errorMessage, onRetry: context.read<AbsenceControlCubit>().start);
              case ViewStatus.loaded:
                return user.isStudent
                    ? _StudentAbsence(user: user, state: state)
                    : _InstructorAbsence(user: user, state: state);
            }
          },
        ),
      ),
    );
  }
}

class _StudentAbsence extends StatelessWidget {
  const _StudentAbsence({required this.user, required this.state});

  final UserEntity user;
  final AbsenceControlState state;

  @override
  Widget build(BuildContext context) {
    final records = state.recordsFor(user.uid);
    if (records.isEmpty) {
      return const EmptyStateView(
        icon: Icons.event_available_outlined,
        title: 'Devamsızlık kaydın yok',
        message: 'Yoklamalar işlendikçe ders bazlı devamsızlık durumun burada görünür.',
      );
    }
    final critical = state.criticalFor(user.uid);
    final rate = state.attendanceRateFor(user.uid);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(top: AppDimensions.p8, bottom: AppDimensions.p32),
      children: [
        EduCard(
          margin: const EdgeInsets.all(AppDimensions.p16),
          gradient: critical.isEmpty ? AppColors.studentHeroGradient : null,
          tint: critical.isEmpty ? null : AppColors.criticalAbsenceRed.withValues(alpha: 0.1),
          glowColor: critical.isEmpty ? null : AppColors.criticalAbsenceRed,
          highlighted: critical.isNotEmpty,
          child: Row(
            children: [
              Text(
                '%${rate.round()}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: critical.isEmpty ? Colors.white : AppColors.criticalAbsenceRed,
                ),
              ),
              const SizedBox(width: AppDimensions.p16),
              Expanded(
                child: Text(
                  critical.isEmpty
                      ? 'Genel ders katılımın. Tüm derslerde %20 devamsızlık sınırının altındasın. 👏'
                      : '${critical.length} derste kritik risk! ${AppStrings.criticalRiskNotification}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: critical.isEmpty ? Colors.white : AppColors.criticalAbsenceRed,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Ders Bazlı Devamsızlık'),
        for (final r in records)
          StudentAbsenceProgressCard(
            courseName: r.courseName,
            totalCourseHours: r.totalHours,
            absentHours: r.absentHours,
          ),
      ],
    );
  }
}

class _InstructorAbsence extends StatelessWidget {
  const _InstructorAbsence({required this.user, required this.state});

  final UserEntity user;
  final AbsenceControlState state;

  Future<void> _warn(BuildContext context, StudentAbsenceRecordEntity record) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AbsenceControlCubit>().sendPushWarning(actor: user, record: record);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${record.studentName} öğrencisine devamsızlık uyarısı gönderildi.'),
          backgroundColor: AppColors.criticalAbsenceRed,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(Failure.from(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final critical = state.criticalRecords;
    final byCourse = state.byCourse;
    final recordById = {for (final r in critical) r.id: r};

    return ListView(
      padding: const EdgeInsets.only(top: AppDimensions.p8, bottom: AppDimensions.p32),
      children: [
        CriticalAbsenceRedList(
          atRiskStudents: [
            for (final r in critical)
              CriticalAbsenceItem(
                studentUid: r.id,
                studentName: r.studentName,
                studentNo: r.studentNo,
                courseName: r.courseName,
                absentHours: r.absentHours,
                totalCourseHours: r.totalHours,
                absencePercentage: r.percentage,
              ),
          ],
          onSendPushWarning: (item) {
            final record = recordById[item.studentUid];
            if (record != null) _warn(context, record);
          },
        ),
        const SectionHeader(title: 'Ders Bazlı Devamsızlık Listesi'),
        for (final entry in byCourse.entries)
          EduCard(
            margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              shape: const Border(),
              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${entry.value.length} öğrenci • ${entry.value.where((r) => r.isCritical).length} kritik'),
              children: [
                for (final r in entry.value)
                  ListTile(
                    dense: true,
                    title: Text(r.studentName),
                    subtitle: Text('${r.studentNo} • ${r.absentHours}/${r.totalHours} saat'),
                    trailing: Text(
                      '%${r.percentage.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: r.isCritical
                            ? AppColors.criticalAbsenceRed
                            : (r.isWarning ? AppColors.warningAmber : AppColors.resolvedGreen),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
