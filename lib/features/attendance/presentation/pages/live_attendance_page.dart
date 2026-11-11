import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/attendance_status.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../../../core/widgets/atmosphere/ambient_background.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/edu_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../../../schedule/presentation/cubit/schedule_cubit.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../cubit/live_attendance_cubit.dart';
import '../cubit/live_attendance_state.dart';
import '../widgets/dynamic_qr_pin_board.dart';
import '../widgets/live_attendance_roster_tabs.dart';
import '../widgets/student_qr_pin_scanner.dart';

/// [LiveAttendancePage] Modül 2.1 — 60 Sn Canlı Yoklama Kalkanı.
/// - Eğitmen: oturum başlatır, 60 sn'de bir yenilenen PIN/QR panosunu yansıtır,
///   canlı listeyi düzenler ve oturumu kapatır (devamsızlıklar işlenir).
/// - Öğrenci: eğitmenin ekranındaki 4 haneli PIN ile derse katılır.
class LiveAttendancePage extends StatelessWidget {
  const LiveAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(title: AppStrings.navLiveAttendance, currentRole: user.role),
        body: BlocBuilder<LiveAttendanceCubit, LiveAttendanceState>(
          builder: (context, state) {
            switch (state.status) {
              case ViewStatus.initial:
              case ViewStatus.loading:
                return const LoadingStateView();
              case ViewStatus.failure:
                return ErrorStateView(message: state.errorMessage, onRetry: context.read<LiveAttendanceCubit>().start);
              case ViewStatus.loaded:
                return user.isInstructor
                    ? _InstructorView(user: user, state: state)
                    : _StudentView(user: user, state: state);
            }
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EĞİTMEN
// -----------------------------------------------------------------------------

class _InstructorView extends StatelessWidget {
  const _InstructorView({required this.user, required this.state});

  final UserEntity user;
  final LiveAttendanceState state;

  @override
  Widget build(BuildContext context) {
    final session = state.activeSessionFor(user.uid);
    if (session == null) return _StartSessionPanel(user: user, state: state);
    return _ActiveSessionPanel(user: user, session: session, isBusy: state.isBusy);
  }
}

class _StartSessionPanel extends StatefulWidget {
  const _StartSessionPanel({required this.user, required this.state});

  final UserEntity user;
  final LiveAttendanceState state;

  @override
  State<_StartSessionPanel> createState() => _StartSessionPanelState();
}

class _StartSessionPanelState extends State<_StartSessionPanel> {
  String? _selectedCourseId;

  Future<void> _start(CourseScheduleEntity course) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<LiveAttendanceCubit>().startSession(actor: widget.user, course: course);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(Failure.from(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleCubit>().state;
    final mine = schedule.courses.where((c) => c.instructorUid == widget.user.uid).toList();
    final courses = mine.isNotEmpty ? mine : schedule.courses;
    final ongoing = schedule.ongoingCourse();
    final suggested = courses.where((c) => c.id == ongoing?.id).firstOrNull ?? courses.firstOrNull;
    final selectedId = _selectedCourseId ?? suggested?.id;
    final selected = courses.where((c) => c.id == selectedId).firstOrNull;
    final past = widget.state.pastSessionsBy(widget.user.uid);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.p32),
      children: [
        EduCard(
          margin: const EdgeInsets.all(AppDimensions.p16),
          gradient: AppColors.attendanceCtaLightGradient,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 40),
                const SizedBox(height: AppDimensions.p8),
                Text(
                  'Canlı yoklama başlat',
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  '${AppStrings.qrExpirationNotice} Kod her 60 saniyede otomatik yenilenir; '
                  'öğrenciler PIN\'i kendi cihazlarından girer.',
                ),
              ],
            ),
          ),
        ),
        SectionHeader(title: 'Ders seçin${ongoing != null ? ' (şu an: ${ongoing.courseCode})' : ''}'),
        if (courses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppDimensions.p20),
            child: Text('Ders programında ders bulunmuyor. Önce Ders Programı sekmesinden ders ekleyin.'),
          ),
        for (final c in courses)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: 4),
            child: EduCard(
              highlighted: c.id == selectedId,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p12, vertical: AppDimensions.p4),
              onTap: () => setState(() => _selectedCourseId = c.id),
              child: Row(
                children: [
                  Icon(
                    c.id == selectedId ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: c.id == selectedId ? theme.colorScheme.primary : null,
                  ),
                  const SizedBox(width: AppDimensions.p12),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${c.courseCode} • ${c.courseName}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${DateTimeHelper.dayName(c.dayOfWeek)} ${c.timeRange} • ${c.roomLocation}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.p16),
          child: ElevatedButton.icon(
            onPressed: (selected == null || widget.state.isBusy) ? null : () => _start(selected),
            icon: widget.state.isBusy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow_rounded),
            label: Text(selected == null ? 'Ders seçin' : '${selected.courseCode} için ${AppStrings.startAttendance}'),
          ),
        ),
        if (past.isNotEmpty) ...[
          const SectionHeader(title: 'Son Yoklamalar'),
          for (final s in past)
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text('${s.courseCode} • ${DateTimeHelper.formatDateTime(s.startedAt)}'),
              subtitle: Text(
                'Gelen ${s.countOf(AttendanceStatus.present)} • Gelmeyen ${s.countOf(AttendanceStatus.absent)} • '
                'İzinli ${s.countOf(AttendanceStatus.excused)}',
              ),
            ),
        ],
      ],
    );
  }
}

class _ActiveSessionPanel extends StatefulWidget {
  const _ActiveSessionPanel({required this.user, required this.session, required this.isBusy});

  final UserEntity user;
  final AttendanceSessionEntity session;
  final bool isBusy;

  @override
  State<_ActiveSessionPanel> createState() => _ActiveSessionPanelState();
}

class _ActiveSessionPanelState extends State<_ActiveSessionPanel> {
  @override
  void initState() {
    super.initState();
    _refreshIfExpired();
  }

  @override
  void didUpdateWidget(covariant _ActiveSessionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshIfExpired();
  }

  String? _autoRefreshedToken;

  /// Sayfa kapalıyken PIN'in süresi dolduysa açılışta hemen yeni kod üret
  /// (aynı kod için yalnızca bir kez; hata durumunda döngüye girmez).
  void _refreshIfExpired() {
    if (!widget.session.isPinExpired() || _autoRefreshedToken == widget.session.qrToken) return;
    _autoRefreshedToken = widget.session.qrToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
    });
  }

  void _refresh() => context.read<LiveAttendanceCubit>().refreshPin(actor: widget.user, sessionId: widget.session.id);

  Future<void> _end() async {
    final cubit = context.read<LiveAttendanceCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final s = widget.session;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yoklamayı bitir'),
        content: Text(
          '${s.countOf(AttendanceStatus.absent)} öğrenci "Gelmeyen" olarak kalacak ve devamsızlıklarına '
          '${s.sessionHours} saat eklenecek. Oturum kapatılsın mı?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bitir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final summary = await cubit.endSession(actor: widget.user, sessionId: s.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Yoklama kapatıldı: ${summary.present} gelen, ${summary.absent} gelmeyen, ${summary.excused} izinli.'
            '${summary.newlyCritical > 0 ? ' ${summary.newlyCritical} öğrenci %20 sınırını aştı ve uyarıldı.' : ''}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(Failure.from(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final cubit = context.read<LiveAttendanceCubit>();
    final attendees = [
      for (final m in s.marks)
        AttendeeItem(
          studentUid: m.studentUid,
          studentName: m.studentName,
          studentNo: m.studentNo,
          status: m.status,
          recordedAt: m.recordedAt,
        ),
    ]..sort((a, b) => a.studentName.compareTo(b.studentName));

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.p32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.p20, AppDimensions.p12, AppDimensions.p20, 0),
          child: Text(
            '${s.courseCode} • ${s.courseName}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p20),
          child: Text('Başlangıç: ${DateTimeHelper.formatTime(s.startedAt)} • ${s.sessionHours} ders saati'),
        ),
        DynamicQrPinBoard(
          // Her yeni kodda pano yeniden kurulur; geri sayım 60'tan başlar.
          key: ValueKey(s.qrToken),
          pinCode: s.pinCode,
          qrToken: s.qrToken,
          remainingSeconds: s.remainingSeconds(),
          courseLabel: s.courseCode,
          onExpireOrRefresh: _refresh,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
          child: Row(
            children: [
              for (final status in AttendanceStatus.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: EduCard(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.p10),
                      glowColor: status.color,
                      child: Column(
                        children: [
                          Text(
                            '${s.countOf(status)}',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: status.color),
                          ),
                          Text(status.displayName, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.p12),
        LiveAttendanceRosterTabs(
          attendees: attendees,
          onStatusChanged: (item, status) =>
              cubit.setStatus(actor: widget.user, sessionId: s.id, studentUid: item.studentUid, status: status),
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.p16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Kodu Yenile'),
                ),
              ),
              const SizedBox(width: AppDimensions.p12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.criticalAbsenceRed),
                  onPressed: widget.isBusy ? null : _end,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Yoklamayı Bitir'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ÖĞRENCİ
// -----------------------------------------------------------------------------

class _StudentView extends StatelessWidget {
  const _StudentView({required this.user, required this.state});

  final UserEntity user;
  final LiveAttendanceState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LiveAttendanceCubit>();
    final active = state.activeSessions;
    final history = state.attendedBy(user.uid);
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return ListView(
      padding: const EdgeInsets.only(top: AppDimensions.p8, bottom: AppDimensions.p32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
          child: EduCard(
            glowColor: active.isEmpty ? null : AppColors.secondaryLight,
            highlighted: active.isNotEmpty,
            child: Row(
              children: [
                Icon(
                  active.isEmpty ? Icons.sensors_off_rounded : Icons.sensors_rounded,
                  color: active.isEmpty ? muted : AppColors.secondaryLight,
                ),
                const SizedBox(width: AppDimensions.p12),
                Expanded(
                  child: Text(
                    active.isEmpty
                        ? 'Şu anda açık bir yoklama yok. Eğitmen yoklamayı başlattığında PIN ile katılabilirsin.'
                        : 'Açık yoklama: ${active.map((s) => '${s.courseCode} (${s.instructorName})').join(', ')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        StudentQrPinScanner(
          errorMessageBuilder: (e) => Failure.from(e).message,
          onSubmitPin: (pin) async {
            final session = await cubit.submitCode(actor: user, code: pin);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${session.courseCode} dersine katılımın kaydedildi. ✅'),
                backgroundColor: AppColors.resolvedGreen,
              ),
            );
          },
          onOpenQrScanner: () => showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('QR ile katılım'),
              content: const Text(
                'Kamera ile QR okutma bu sürümde desteklenmiyor. Eğitmenin panosundaki 4 haneli PIN kodunu '
                'girerek aynı şekilde yoklamaya katılabilirsin.',
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p20, vertical: AppDimensions.p4),
          child: Text(AppStrings.qrExpirationNotice, style: TextStyle(color: muted, fontSize: 12)),
        ),
        if (history.isNotEmpty) ...[
          const SectionHeader(title: 'Son Katıldığın Yoklamalar'),
          for (final s in history)
            ListTile(
              leading: const Icon(Icons.check_circle_rounded, color: AppColors.resolvedGreen),
              title: Text('${s.courseCode} • ${s.courseName}'),
              subtitle: Text(DateTimeHelper.formatDateTime(s.markFor(user.uid)?.recordedAt ?? s.startedAt)),
            ),
        ],
      ],
    );
  }
}
