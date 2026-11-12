import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/submission_status.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../../../core/widgets/role_visibility_guard.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../../schedule/presentation/widgets/course_dropdown.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/submission_entity.dart';
import '../cubit/assignment_cubit.dart';
import '../cubit/assignment_state.dart';
import '../widgets/assignment_countdown_card.dart';
import '../widgets/create_assignment_sheet.dart';
import '../widgets/late_submission_warning_banner.dart';
import '../widgets/storage_upload_progress_bar.dart';

/// 2.3 ÖDEV KONTROL: öğrenci aktif ödevleri, geri sayımı ve dosya yükleme
/// masasını görür; eğitmen "Yeni Ödev & Rubrik Aç" butonunu ve teslimleri görür.
class AssignmentControlPage extends StatelessWidget {
  const AssignmentControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssignmentCubit>(
      create: (_) => GetIt.instance<AssignmentCubit>()..start(),
      child: const _AssignmentView(),
    );
  }
}

class _AssignmentView extends StatelessWidget {
  const _AssignmentView();

  @override
  Widget build(BuildContext context) {
    final role = context.currentRole;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: RoleVisibilityGuard.onlyInstructor(
        currentRole: role,
        child: FloatingActionButton.extended(
          key: const Key('assignment_create'),
          onPressed: () => _openCreateSheet(context),
          icon: const Icon(Icons.post_add_rounded),
          label: const Text('Yeni Ödev & Rubrik Aç'),
        ),
      ),
      body: BlocConsumer<AssignmentCubit, AssignmentState>(
        listenWhen: (p, c) => c.actionMessage != null && p.actionMessage != c.actionMessage,
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.actionMessage!))),
        builder: (context, state) {
          final cubit = context.read<AssignmentCubit>();
          if (state.status == ViewStatus.failure) {
            return ErrorStateView(message: state.errorMessage, onRetry: cubit.start);
          }
          if (state.status.isLoading && state.courses.isEmpty) {
            return const LoadingStateView(message: 'Ödevler yükleniyor...');
          }
          if (state.courses.isEmpty) {
            return const EmptyStateView(title: 'Ders bulunamadı', message: 'Ödevler ders bazında listelenir.');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppDimensions.p16, AppDimensions.p16, AppDimensions.p16, 96),
            children: [
              CourseDropdown(courses: state.courses, selectedCourseId: state.selectedCourseId, onChanged: cubit.selectCourse),
              const SizedBox(height: AppDimensions.p16),
              if (state.status.isLoading)
                const Padding(padding: AppDimensions.paddingAll24, child: Center(child: CircularProgressIndicator()))
              else if (state.assignments.isEmpty)
                const EmptyStateView(
                  title: 'Aktif ödev yok',
                  message: 'Bu derse ait yayınlanmış ödev bulunmuyor.',
                  icon: Icons.assignment_turned_in_outlined,
                )
              else
                for (final a in state.assignments) ...[
                  AssignmentCountdownCard(
                    key: ValueKey<String>('assignment_${a.assignmentId}'),
                    title: a.title,
                    courseName: a.courseName,
                    description: a.description,
                    dueDate: a.dueDate,
                    status: role == UserRole.student
                        ? _statusOf(state, context, a.assignmentId)
                        : SubmissionStatus.pending,
                    onTap: () => role == UserRole.instructor
                        ? _openSubmissions(context, a)
                        : _openSubmissionDesk(context, a),
                    onSubmitPressed: role == UserRole.student ? () => _openSubmissionDesk(context, a) : null,
                  ),
                  const SizedBox(height: AppDimensions.p12),
                ],
            ],
          );
        },
      ),
    );
  }

  static SubmissionStatus _statusOf(
    AssignmentState state,
    BuildContext context,
    String assignmentId,
  ) {
    final uid = context.readCurrentUser()?.uid;
    return (uid == null
                ? null
                : state.submissionOfForAssignment(assignmentId, uid))
            ?.status ??
        SubmissionStatus.pending;
  }

  static Future<void> _openCreateSheet(BuildContext context) {
    final cubit = context.read<AssignmentCubit>();
    final courses = <String, String>{for (final c in cubit.state.courses) c.courseId: c.courseName};
    return CreateAssignmentSheet.show(
      context,
      courses: courses,
      onCreate: ({
        required String courseId,
        required String courseName,
        required String title,
        required String description,
        required String rubricCriteria,
        required DateTime dueDate,
      }) async {
        await cubit.createAssignment(
          courseId: courseId,
          courseName: courseName,
          title: title,
          description: description,
          rubricCriteria: rubricCriteria,
          dueDate: dueDate,
        );
      },
    );
  }

  /// Öğrenci: teslim masası (durum, gecikme uyarısı, dosya seç + yükle).
  static Future<void> _openSubmissionDesk(BuildContext context, AssignmentEntity assignment) {
    final cubit = context.read<AssignmentCubit>()..openAssignment(assignment.assignmentId);
    final user = context.readCurrentUser();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider<AssignmentCubit>.value(
        value: cubit,
        child: _SubmissionDesk(assignment: assignment, user: user),
      ),
    ).whenComplete(cubit.clearUpload);
  }

  /// Eğitmen: teslim listesi → notlandırma detayına geçiş.
  static Future<void> _openSubmissions(BuildContext context, AssignmentEntity assignment) {
    final cubit = context.read<AssignmentCubit>()..openAssignment(assignment.assignmentId);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => BlocProvider<AssignmentCubit>.value(
        value: cubit,
        child: _SubmissionList(
          assignment: assignment,
          onOpen: (s) {
            Navigator.pop(sheetContext);
            context.push(
              RouteNames.submissionGradingPath(
                s.submissionId,
                assignmentId: assignment.assignmentId,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SubmissionDesk extends StatelessWidget {
  const _SubmissionDesk({required this.assignment, required this.user});

  final AssignmentEntity assignment;
  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AssignmentCubit, AssignmentState>(
      builder: (context, state) {
        final uid = user?.uid;
        final mine = uid == null ? null : state.submissionOf(uid);
        final isPastDue = DateTime.now().isAfter(assignment.dueDate);
        final upload = state.upload?.assignmentId == assignment.assignmentId ? state.upload : null;
        final remaining = DateTimeHelper.timeUntil(assignment.dueDate);

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(assignment.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppDimensions.p4),
                Text(
                  isPastDue
                      ? 'Son teslim tarihi geçti'
                      : 'Kalan süre: ${DateTimeHelper.formatCountdownWithDays(remaining)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPastDue ? AppColors.lateSubmissionOrange : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.p12),
                Text(assignment.description),
                if (assignment.rubricCriteria.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.p12),
                  Text('Puanlama Rubriği', style: theme.textTheme.titleSmall),
                  Text(assignment.rubricCriteria),
                ],
                const SizedBox(height: AppDimensions.p16),
                if (isPastDue && mine == null) ...[
                  const LateSubmissionWarningBanner(),
                  const SizedBox(height: AppDimensions.p12),
                ],
                if (mine != null) _MySubmission(submission: mine),
                if (upload != null) ...[
                  StorageUploadProgressBar(
                    progress: upload.progress,
                    fileName: upload.fileName,
                    isUploading: upload.isUploading,
                    isCompleted: upload.isCompleted,
                    errorMessage: upload.errorMessage,
                  ),
                  const SizedBox(height: AppDimensions.p12),
                ],
                if (mine?.status != SubmissionStatus.graded)
                  FilledButton.icon(
                    key: const Key('assignment_pick_upload'),
                    onPressed: (upload?.isUploading ?? false) || uid == null
                        ? null
                        : () => _pickAndUpload(context, uid, user?.fullName ?? ''),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(mine == null ? 'Dosya Seç ve Teslim Et' : 'Yeni Dosya ile Tekrar Teslim Et'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(BuildContext context, String uid, String name) async {
    final cubit = context.read<AssignmentCubit>();
    final picked = await GetIt.instance<FilePickerService>().pickAssignmentFile();
    final path = picked?.path;
    if (picked == null || path == null) return;
    await cubit.uploadSubmission(
      assignment: assignment,
      studentUid: uid,
      studentName: name,
      localFilePath: path,
      fileName: picked.name,
    );
  }
}

class _MySubmission extends StatelessWidget {
  const _MySubmission({required this.submission});

  final SubmissionEntity submission;

  @override
  Widget build(BuildContext context) {
    final graded = submission.status == SubmissionStatus.graded;
    return Card(
      child: Padding(
        padding: AppDimensions.paddingAll12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined),
                const SizedBox(width: AppDimensions.p8),
                Expanded(child: Text(submission.fileName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(submission.status.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            if (submission.isLatePenaltyApplied) ...[
              const SizedBox(height: AppDimensions.p8),
              const LateSubmissionWarningBanner.badge(),
            ],
            if (graded) ...[
              const SizedBox(height: AppDimensions.p8),
              Text(
                'Puan: ${submission.finalScore?.toStringAsFixed(0) ?? '-'} / 100'
                '${submission.isLatePenaltyApplied ? ' (ham puan ${submission.rawScore?.toStringAsFixed(0)})' : ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if ((submission.writtenFeedback ?? '').isNotEmpty) Text('Geri bildirim: ${submission.writtenFeedback}'),
              if ((submission.audioFeedbackUrl ?? '').isNotEmpty)
                Row(
                  children: [
                    const Expanded(child: Text('Sesli geri bildirim mevcut.')),
                    TextButton.icon(
                      onPressed: () => context
                          .read<AssignmentCubit>()
                          .playAudioFeedback(submission.audioFeedbackUrl),
                      icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                      label: const Text('Dinle'),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubmissionList extends StatelessWidget {
  const _SubmissionList({required this.assignment, required this.onOpen});

  final AssignmentEntity assignment;
  final ValueChanged<SubmissionEntity> onOpen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssignmentCubit, AssignmentState>(
      builder: (context, state) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: AppDimensions.paddingH16V8,
                  child: Text('${assignment.title} · Teslimler', style: Theme.of(context).textTheme.titleMedium),
                ),
                if (state.submissionsStatus.isLoading)
                  const Padding(padding: AppDimensions.paddingAll24, child: Center(child: CircularProgressIndicator()))
                else if (state.submissions.isEmpty)
                  const Padding(padding: AppDimensions.paddingAll24, child: Text('Henüz teslim yok.'))
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.submissions.length,
                      itemBuilder: (context, i) {
                        final s = state.submissions[i];
                        return ListTile(
                          leading: Icon(
                            s.status == SubmissionStatus.graded ? Icons.grading_rounded : Icons.description_outlined,
                          ),
                          title: Text(s.studentName, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${s.fileName} · ${s.status.label}'
                            '${s.finalScore != null ? ' · ${s.finalScore!.toStringAsFixed(0)} puan' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: s.isLatePenaltyApplied
                              ? const Icon(Icons.timer_off_rounded, color: AppColors.lateSubmissionOrange)
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () => onOpen(s),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
