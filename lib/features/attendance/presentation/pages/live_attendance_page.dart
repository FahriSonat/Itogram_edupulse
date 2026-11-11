import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/attendance_status.dart';
import '../../../../core/widgets/role_visibility_guard.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../../../schedule/presentation/cubit/schedule_cubit.dart';
import '../../../schedule/presentation/cubit/schedule_state.dart';
import '../../../schedule/presentation/widgets/course_dropdown.dart';
import '../cubit/live_attendance_cubit.dart';
import '../cubit/live_attendance_state.dart';
import '../widgets/dynamic_qr_pin_board.dart';
import '../widgets/live_attendance_roster_tabs.dart';
import '../widgets/student_qr_pin_scanner.dart';

/// 2.2 CANLI YOKLAMA: öğrenci 4 haneli PIN girer (QR okutma kamera paketi
/// eklenince açılır); eğitmen 60 saniyede bir yenilenen QR + PIN'i ve canlı
/// Gelen / Gelmeyen / İzinli listesini görür.
class LiveAttendancePage extends StatelessWidget {
  const LiveAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sl = GetIt.instance;
    final role = context.currentRole;
    return BlocProvider<LiveAttendanceCubit>(
      create: (_) => sl<LiveAttendanceCubit>(),
      child: RoleVisibilityGuard(
        currentRole: role,
        studentBuilder: (_) => const _StudentAttendanceView(),
        instructorBuilder: (_) => BlocProvider<ScheduleCubit>(
          create: (_) => sl<ScheduleCubit>()..start(),
          child: const _InstructorAttendanceView(),
        ),
      ),
    );
  }
}

// =========================================================================
// Öğrenci
// =========================================================================

class _StudentAttendanceView extends StatelessWidget {
  const _StudentAttendanceView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<LiveAttendanceCubit, LiveAttendanceState>(
      builder: (context, state) {
        if (state.status == LiveAttendanceStatus.submitted) {
          return _SuccessView(onAgain: context.read<LiveAttendanceCubit>().resetStudent);
        }
        return SingleChildScrollView(
          padding: AppDimensions.paddingAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Derse Katıl', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppDimensions.p4),
              Text(
                'Eğitmenin ekranındaki 4 haneli PIN kodunu gir. Kod 60 saniye geçerlidir; '
                'süresi dolan kodla yoklama verilemez.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.p16),
              StudentQrPinScanner(
                onSubmitPin: (pin) => _submit(context, pin),
                // QR kamera tarayıcı paketi (mobile_scanner) henüz projede yok.
                onOpenQrScanner: null,
                errorMessageBuilder: (e) => e.toString().replaceFirst('Exception: ', ''),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget hatayı kendi gösterir; bu yüzden başarısızlıkta istisna fırlatılır.
  static Future<void> _submit(BuildContext context, String pin) async {
    final user = context.readCurrentUser();
    if (user == null) throw Exception('Oturum bulunamadı.');
    final cubit = context.read<LiveAttendanceCubit>();
    await cubit.submitCode(studentUid: user.uid, code: pin);
    final state = cubit.state;
    if (state.status == LiveAttendanceStatus.failure) {
      throw Exception(state.isCodeExpired
          ? 'Kodun 60 saniyelik süresi doldu. Eğitmenden yeni kodu iste.'
          : (state.message ?? 'Yoklama verilemedi.'));
    }
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onAgain});

  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppDimensions.paddingAll24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 72, color: AppColors.resolvedGreen),
            const SizedBox(height: AppDimensions.p16),
            Text('Yoklaman alındı', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppDimensions.p8),
            const Text('Bu dersteki katılımın "Geldi" olarak kaydedildi.', textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.p24),
            OutlinedButton(onPressed: onAgain, child: const Text('Başka bir derse katıl')),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Eğitmen
// =========================================================================

class _InstructorAttendanceView extends StatefulWidget {
  const _InstructorAttendanceView();

  @override
  State<_InstructorAttendanceView> createState() => _InstructorAttendanceViewState();
}

class _InstructorAttendanceViewState extends State<_InstructorAttendanceView> {
  String? _courseId;

  List<CourseScheduleEntity> _unique(List<CourseScheduleEntity> all) {
    final seen = <String>{};
    return [for (final c in all) if (seen.add(c.courseId)) c];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<LiveAttendanceCubit, LiveAttendanceState>(
      listenWhen: (p, c) => c.message != null && p.message != c.message,
      listener: (context, state) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!))),
      builder: (context, live) {
        final cubit = context.read<LiveAttendanceCubit>();
        final isActive = live.status == LiveAttendanceStatus.active;
        final session = live.session;

        return BlocBuilder<ScheduleCubit, ScheduleState>(
          builder: (context, schedule) {
            final courses = _unique(schedule.courses);
            if (schedule.status.isLoading) return const LoadingStateView(message: 'Dersler yükleniyor...');
            if (courses.isEmpty) {
              return const EmptyStateView(
                title: 'Ders bulunamadı',
                message: 'Yoklama başlatmak için önce Ders Programı\'na ders ekleyin.',
                icon: Icons.event_busy_rounded,
              );
            }
            final selectedId = _courseId ?? courses.first.courseId;
            final course = courses.firstWhere((c) => c.courseId == selectedId, orElse: () => courses.first);

            return ListView(
              padding: AppDimensions.paddingAll16,
              children: [
                if (!isActive) ...[
                  Text('Canlı Yoklama', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppDimensions.p12),
                  CourseDropdown(
                    courses: courses,
                    selectedCourseId: course.courseId,
                    onChanged: (id) => setState(() => _courseId = id),
                  ),
                  const SizedBox(height: AppDimensions.p16),
                  FilledButton.icon(
                    key: const Key('attendance_start'),
                    onPressed: live.status == LiveAttendanceStatus.starting
                        ? null
                        : () => cubit.startSession(course.courseId),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    icon: live.status == LiveAttendanceStatus.starting
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Yoklamayı Başlat'),
                  ),
                ] else if (session != null) ...[
                  DynamicQrPinBoard(
                    key: ValueKey<String>(session.sessionId),
                    pinCode: session.pinCode,
                    qrToken: session.qrCodeToken,
                    expiresAt: session.expiresAt,
                    remainingSeconds: live.remainingSeconds,
                    courseLabel: '${course.courseCode} · ${course.courseName}',
                  ),
                  const SizedBox(height: AppDimensions.p12),
                  Row(
                    children: [
                      _Count(label: 'Gelen', value: live.countOf(AttendanceStatus.present), color: AppColors.resolvedGreen),
                      _Count(label: 'Gelmeyen', value: live.countOf(AttendanceStatus.absent), color: AppColors.criticalAbsenceRed),
                      _Count(label: 'İzinli', value: live.countOf(AttendanceStatus.excused), color: AppColors.warningAmber),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.p12),
                  LiveAttendanceRosterTabs(
                    attendees: [
                      for (final entry in live.statuses.entries)
                        AttendeeItem(
                          studentUid: entry.key,
                          studentName: live.students[entry.key]?.name ?? entry.key,
                          studentNo: live.students[entry.key]?.studentNo ?? '',
                          status: entry.value,
                        ),
                    ],
                    onStatusChanged: (item, status) => cubit.changeStatus(item.studentUid, status),
                  ),
                  const SizedBox(height: AppDimensions.p16),
                  OutlinedButton.icon(
                    key: const Key('attendance_stop'),
                    onPressed: cubit.stopSession,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Yoklamayı Bitir'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
          Text(label, style: Theme.of(context).textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
