import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/enums/submission_status.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../../../core/widgets/countdown_timer_widget.dart';
import '../../../../core/widgets/edu_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../../schedule/presentation/cubit/schedule_cubit.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/submission_entity.dart';
import '../cubit/assignment_cubit.dart';
import '../cubit/assignment_state.dart';
import '../widgets/assignment_countdown_card.dart';
import '../widgets/audio_written_feedback_box.dart';
import '../widgets/create_assignment_sheet.dart';
import '../widgets/late_submission_warning_banner.dart';
import '../widgets/storage_upload_progress_bar.dart';

/// [AssignmentControlPage] Modül 1.3: ödev teslim (öğrenci) ve ödev yönetimi (eğitmen).
class AssignmentControlPage extends StatelessWidget {
  const AssignmentControlPage({super.key});

  /// Eğitmen: rubrikli yeni ödev formu.
  static Future<void> openCreateSheet(BuildContext context) {
    final user = context.currentUser;
    final cubit = context.read<AssignmentCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final courses = context.read<ScheduleCubit>().state.courseNames;
    return CreateAssignmentSheet.show(
      context,
      courses: {for (final name in courses) name: name},
      onCreate:
          ({
            required courseId,
            required courseName,
            required title,
            required description,
            required rubricCriteria,
            required dueDate,
          }) async {
            await cubit.createAssignment(
              actor: user,
              courseName: courseName,
              title: title,
              description: description,
              rubricCriteria: rubricCriteria,
              dueDate: dueDate,
            );
            messenger.showSnackBar(SnackBar(content: Text('"$title" ödevi öğrencilere yayınlandı.')));
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    return BlocBuilder<AssignmentCubit, AssignmentState>(
      builder: (context, state) {
        switch (state.status) {
          case ViewStatus.initial:
          case ViewStatus.loading:
            return const LoadingStateView();
          case ViewStatus.failure:
            return ErrorStateView(message: state.errorMessage, onRetry: context.read<AssignmentCubit>().start);
          case ViewStatus.loaded:
            break;
        }
        if (state.assignments.isEmpty) {
          return EmptyStateView(
            icon: Icons.assignment_outlined,
            title: 'Henüz ödev yok',
            message: user.isInstructor
                ? 'Öğrencilerinize ilk ödevi yayınlayın.'
                : 'Eğitmenleriniz ödev yayınladığında burada göreceksiniz.',
            actionLabel: user.isInstructor ? 'Yeni Ödev' : null,
            onAction: user.isInstructor ? () => openCreateSheet(context) : null,
          );
        }
        return user.isStudent ? _StudentAssignments(user: user, state: state) : _InstructorAssignments(state: state);
      },
    );
  }
}

// -----------------------------------------------------------------------------
// ÖĞRENCİ GÖRÜNÜMÜ
// -----------------------------------------------------------------------------

class _StudentAssignments extends StatelessWidget {
  const _StudentAssignments({required this.user, required this.state});

  final UserEntity user;
  final AssignmentState state;

  Future<void> _submit(BuildContext context, AssignmentEntity assignment) async {
    final cubit = context.read<AssignmentCubit>();
    final messenger = ScaffoldMessenger.of(context);

    if (assignment.isPastDue()) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Geç teslim'),
          content: const Text(
            'Son teslim tarihi geçti. Teslim edebilirsiniz ancak değerlendirmede 10 puan gecikme cezası uygulanacak.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yine de Teslim Et')),
          ],
        ),
      );
      if (proceed != true) return;
    }

    PickedFileInfo? file;
    try {
      file = await sl<FilePickerService>().pickDocument();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Dosya seçici açılamadı: $e')));
      return;
    }
    if (file == null) return;

    final error = await cubit.submit(actor: user, assignment: assignment, file: file);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? '${file.name} başarıyla teslim edildi!'),
        backgroundColor: error == null ? AppColors.resolvedGreen : AppColors.criticalAbsenceRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = state.openAssignmentsFor(user.uid);
    final submitted = state.assignments.where((a) => state.submissionFor(a.id, user.uid) != null).toList();
    final upload = state.upload;

    return ListView(
      padding: const EdgeInsets.only(top: AppDimensions.p8, bottom: AppDimensions.p32),
      children: [
        if (state.hasOverdueFor(user.uid)) const LateSubmissionWarningBanner(penaltyPoints: 10),
        if (upload != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StorageUploadProgressBar(
                  progress: upload.progress,
                  fileName: upload.fileName,
                  fileSize: upload.fileSize,
                  isUploading: upload.isUploading,
                  isCompleted: upload.isCompleted,
                  errorMessage: upload.errorMessage,
                ),
                if (!upload.isUploading)
                  TextButton(onPressed: context.read<AssignmentCubit>().dismissUpload, child: const Text('Kapat')),
              ],
            ),
          ),
        SectionHeader(title: 'Açık Ödevler (${open.length})'),
        if (open.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.p20, vertical: AppDimensions.p8),
            child: Text('Tüm ödevlerini teslim ettin. 👏'),
          ),
        for (final a in open)
          AssignmentCountdownCard(
            title: a.title,
            courseName: a.courseName,
            description: a.description,
            dueDate: a.dueDate,
            status: state.statusFor(a, user.uid),
            onSubmitPressed: (upload?.isUploading ?? false) ? null : () => _submit(context, a),
          ),
        if (submitted.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.p8),
          SectionHeader(title: 'Teslim Ettiklerim (${submitted.length})'),
          for (final a in submitted)
            _SubmittedAssignmentTile(
              assignment: a,
              submission: state.submissionFor(a.id, user.uid)!,
              onResubmit: (upload?.isUploading ?? false) ? null : () => _submit(context, a),
            ),
        ],
      ],
    );
  }
}

class _SubmittedAssignmentTile extends StatelessWidget {
  const _SubmittedAssignmentTile({required this.assignment, required this.submission, this.onResubmit});

  final AssignmentEntity assignment;
  final SubmissionEntity submission;
  final VoidCallback? onResubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final graded = submission.isGraded;

    return EduCard(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.courseName, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
                    const SizedBox(height: 2),
                    Text(assignment.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _ScoreBadge(submission: submission),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          Row(
            children: [
              Icon(Icons.attach_file_rounded, size: 16, color: muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${submission.fileName} • ${PickedFileInfo.formatBytes(submission.fileSizeBytes)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Teslim: ${DateTimeHelper.formatDateTime(submission.submittedAt)}'
            '${submission.isLate ? '  •  ${SubmissionStatus.late.displayName}' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: submission.isLate ? AppColors.lateSubmissionOrange : muted,
              fontWeight: submission.isLate ? FontWeight.w600 : null,
            ),
          ),
          if (graded) ...[
            const SizedBox(height: AppDimensions.p12),
            AudioWrittenFeedbackBox(
              writtenFeedback: submission.writtenFeedback,
              audioFeedbackUrl: submission.audioFeedbackUrl,
            ),
          ] else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onResubmit,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Yeniden Yükle'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.submission});

  final SubmissionEntity submission;

  @override
  Widget build(BuildContext context) {
    final graded = submission.isGraded;
    final color = graded ? AppColors.resolvedGreen : AppColors.warningAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: AppDimensions.radiusFull),
      child: Text(
        graded ? '${submission.finalScore!.toStringAsFixed(0)} / 100' : 'Değerlendiriliyor',
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EĞİTMEN GÖRÜNÜMÜ
// -----------------------------------------------------------------------------

class _InstructorAssignments extends StatelessWidget {
  const _InstructorAssignments({required this.state});

  final AssignmentState state;

  @override
  Widget build(BuildContext context) {
    final active = state.assignments.where((a) => !a.isPastDue()).toList();
    final closed = state.assignments.where((a) => a.isPastDue()).toList();

    return ListView(
      padding: const EdgeInsets.only(top: AppDimensions.p8, bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
          child: EduCard(
            tint: AppColors.tilePurpleLight,
            glowColor: AppColors.metricPurple,
            child: Row(
              children: [
                const Icon(Icons.pending_actions_rounded, color: AppColors.metricPurple),
                const SizedBox(width: AppDimensions.p12),
                Expanded(
                  child: Text(
                    '${state.pendingGradingCount} teslim değerlendirme bekliyor',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        SectionHeader(title: 'Devam Eden Ödevler (${active.length})'),
        for (final a in active) _InstructorAssignmentTile(assignment: a, submissions: state.submissionsFor(a.id)),
        if (closed.isNotEmpty) ...[
          SectionHeader(title: 'Süresi Dolanlar (${closed.length})'),
          for (final a in closed) _InstructorAssignmentTile(assignment: a, submissions: state.submissionsFor(a.id)),
        ],
      ],
    );
  }
}

class _InstructorAssignmentTile extends StatelessWidget {
  const _InstructorAssignmentTile({required this.assignment, required this.submissions});

  final AssignmentEntity assignment;
  final List<SubmissionEntity> submissions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final pending = submissions.where((s) => !s.isGraded).length;

    return EduCard(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      onTap: () => Navigator.of(context).pushNamed(RouteNames.submissionGrading, arguments: assignment.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(assignment.courseName, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
              ),
              CountdownTimerWidget(targetDateTime: assignment.dueDate, isCompact: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(assignment.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Son teslim: ${DateTimeHelper.formatDateTime(assignment.dueDate)}',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: AppDimensions.p8),
          Row(
            children: [
              _Pill(icon: Icons.inbox_rounded, text: '${submissions.length} teslim', color: AppColors.infoBlue),
              const SizedBox(width: 8),
              _Pill(
                icon: Icons.hourglass_bottom_rounded,
                text: '$pending bekliyor',
                color: pending > 0 ? AppColors.warningAmber : AppColors.resolvedGreen,
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppDimensions.radiusFull),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    ),
  );
}
