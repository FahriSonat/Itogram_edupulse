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

/// 2.2 CANLI YOKLAMA EKRANI (Kural 1: Dinamik QR & 4 Haneli PIN Kodu).
/// 
/// - Öğrenci Görünümü: Eğitmenin tahtaya/ekrana yansıttığı 4 haneli PIN kodunu
///   veya QR kodunu girerek derse katılım bildirir. Kod 60 saniyede bir otomatik
///   yenilenir; süresi dolan kodla yoklama verilmesi engellenir.
/// - Eğitmen Görünümü: Dersi seçip "Yoklamayı Başlat" dediğinde 60 saniyede bir
///   yenilenen dinamik QR ve 4 haneli PIN kodunu ([DynamicQrPinBoard]) görüntüler.
///   Aynı zamanda derse katılan öğrencileri canlı olarak Gelen, Gelmeyen ve İzinli
///   sekmelerinde anlık sayılarla ([LiveAttendanceRosterTabs]) takip eder ve manuel düzenleyebilir.
class LiveAttendancePage extends StatelessWidget {
  const LiveAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sl = GetIt.instance;
    final role = context.currentRole;

    // Canlı yoklama işlemlerini yürüten LiveAttendanceCubit inject edilir
    return BlocProvider<LiveAttendanceCubit>(
      create: (_) => sl<LiveAttendanceCubit>(),
      child: RoleVisibilityGuard(
        currentRole: role,
        studentBuilder: (_) => const _StudentAttendanceView(),
        // Eğitmen ekranı için ders listesini çekecek ScheduleCubit sağlanır
        instructorBuilder: (_) => BlocProvider<ScheduleCubit>(
          create: (_) => sl<ScheduleCubit>()..start(),
          child: const _InstructorAttendanceView(),
        ),
      ),
    );
  }
}

// =========================================================================
// Öğrenci Görünümü
// =========================================================================

/// Öğrencinin PIN veya QR okutarak derse katıldığı arayüz.
class _StudentAttendanceView extends StatelessWidget {
  const _StudentAttendanceView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<LiveAttendanceCubit, LiveAttendanceState>(
      builder: (context, state) {
        // Yoklama başarıyla alındıysa yeşil onay ekranı gösterilir
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
              // Kural 1 uyarısı ve 60 saniyelik zaman aşımı açıklaması
              Text(
                'Eğitmenin ekranındaki 4 haneli PIN kodunu gir. Kod 60 saniye geçerlidir; '
                'süresi dolan kodla yoklama verilemez.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.p16),

              // PIN giriş kutuları ve alternatif QR kod okuma butonu
              StudentQrPinScanner(
                onSubmitPin: (pin) => _submit(context, pin),
                onOpenQrScanner: () => _openQrScannerDialog(context),
                errorMessageBuilder: (e) => e.toString().replaceFirst('Exception: ', ''),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Kamera olmadan da test edilebilmesi için açılan QR/Token giriş simülasyon diyaloğu.
  static Future<void> _openQrScannerDialog(BuildContext context) async {
    final controller = TextEditingController();
    final qrCode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('QR Kod ile Katıl'),
        content: TextField(
          key: const Key('qr_token_input'),
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'QR Kod İçeriği veya 4 Haneli PIN',
            hintText: 'EDUPULSE|...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Doğrula'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (qrCode != null && qrCode.isNotEmpty && context.mounted) {
      try {
        await _submit(context, qrCode);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        }
      }
    }
  }

  /// PIN kodunu backend'e doğrulama amacıyla gönderir; süre dolmuşsa hata fırlatır.
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

/// Öğrenci kodu başarıyla doğruladığında gösterilen onay ekranı.
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
// Eğitmen Görünümü
// =========================================================================

/// Eğitmenin yoklama oturumu başlattığı, QR/PIN tahtasını ve katılımcıları yönettiği ekran.
class _InstructorAttendanceView extends StatefulWidget {
  const _InstructorAttendanceView();

  @override
  State<_InstructorAttendanceView> createState() => _InstructorAttendanceViewState();
}

class _InstructorAttendanceViewState extends State<_InstructorAttendanceView> {
  // Seçili olan ders kimliği
  String? _courseId;

  /// Ders listesindeki mükerrer kayıtları temizler.
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

            // Dersler yüklenirken bekleme durumu
            if (schedule.status.isLoading) return const LoadingStateView(message: 'Dersler yükleniyor...');

            // Eğitmenin dersi yoksa boş durum uyarısı
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
                // 1. Durum: Yoklama henüz başlatılmamışsa ders seçimi ve Başlat butonu
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
                ]
                // 2. Durum: Yoklama aktifse canlı QR, 4 haneli PIN ve sayaç paneli
                else if (session != null) ...[
                  DynamicQrPinBoard(
                    key: ValueKey<String>(session.sessionId),
                    pinCode: session.pinCode,
                    qrToken: session.qrCodeToken,
                    expiresAt: session.expiresAt,
                    remainingSeconds: live.remainingSeconds,
                    courseLabel: '${course.courseCode} · ${course.courseName}',
                  ),
                  const SizedBox(height: AppDimensions.p12),

                  // Canlı katılım sayaçları (Gelen / Gelmeyen / İzinli)
                  Row(
                    children: [
                      _Count(label: 'Gelen', value: live.countOf(AttendanceStatus.present), color: AppColors.resolvedGreen),
                      _Count(label: 'Gelmeyen', value: live.countOf(AttendanceStatus.absent), color: AppColors.criticalAbsenceRed),
                      _Count(label: 'İzinli', value: live.countOf(AttendanceStatus.excused), color: AppColors.warningAmber),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.p12),

                  // Katılımcı öğrenci listesi ve manuel durum değiştirme sekmeleri
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

                  // Yoklamayı Sonlandır Butonu
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

/// Katılımcı sayılarını (Gelen, Gelmeyen, İzinli) renkli gösteren sayaç kutusu.
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
