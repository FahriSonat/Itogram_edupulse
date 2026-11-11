import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../../../core/utils/grade_calculator.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/atmosphere/ambient_background.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/edu_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/submission_entity.dart';
import '../cubit/assignment_cubit.dart';
import '../cubit/assignment_state.dart';
import '../widgets/audio_written_feedback_box.dart';

/// [SubmissionGradingDetailPage] eğitmenin bir ödevin teslimlerini puanladığı ekran
/// (yalnızca eğitmen — router [RoleGuard] ile korunur).
class SubmissionGradingDetailPage extends StatefulWidget {
  const SubmissionGradingDetailPage({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  State<SubmissionGradingDetailPage> createState() => _SubmissionGradingDetailPageState();
}

class _SubmissionGradingDetailPageState extends State<SubmissionGradingDetailPage> {
  late final Future<List<UserEntity>> _students = sl<AuthRepository>().getStudents();

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(title: 'Teslim Değerlendirme', currentRole: user.role),
        body: BlocBuilder<AssignmentCubit, AssignmentState>(
          builder: (context, state) {
            final assignment = state.assignmentById(widget.assignmentId);
            if (assignment == null) {
              return const EmptyStateView(icon: Icons.search_off_rounded, title: 'Ödev bulunamadı');
            }
            final submissions = state.submissionsFor(assignment.id);
            return ListView(
              padding: const EdgeInsets.only(bottom: AppDimensions.p32),
              children: [
                _AssignmentSummary(assignment: assignment, submissions: submissions),
                SectionHeader(title: 'Teslimler (${submissions.length})'),
                if (submissions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppDimensions.p20, vertical: AppDimensions.p8),
                    child: Text('Henüz teslim yapılmadı.'),
                  ),
                for (final s in submissions) _SubmissionTile(submission: s, assignment: assignment),
                FutureBuilder<List<UserEntity>>(
                  future: _students,
                  builder: (context, snapshot) {
                    final students = snapshot.data ?? const [];
                    final submittedUids = submissions.map((s) => s.studentUid).toSet();
                    final missing = students.where((s) => !submittedUids.contains(s.uid)).toList();
                    if (missing.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionHeader(title: 'Teslim Etmeyenler (${missing.length})'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final s in missing)
                                Chip(
                                  avatar: const Icon(Icons.person_off_outlined, size: 16),
                                  label: Text('${s.fullName} • ${s.schoolNo}'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AssignmentSummary extends StatelessWidget {
  const _AssignmentSummary({required this.assignment, required this.submissions});

  final AssignmentEntity assignment;
  final List<SubmissionEntity> submissions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final graded = submissions.where((s) => s.isGraded).toList();
    final avg = GradeCalculator.mean(graded.map((s) => s.finalScore!).toList());

    return EduCard(
      margin: const EdgeInsets.all(AppDimensions.p16),
      gradient: AppColors.instructorHeroGradient,
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assignment.courseName, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              assignment.title,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppDimensions.p8),
            Text(assignment.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
            const SizedBox(height: AppDimensions.p8),
            Text('Rubrik: ${assignment.rubricCriteria}', style: const TextStyle(fontSize: 12)),
            Text(
              'Son teslim: ${DateTimeHelper.formatDateTime(assignment.dueDate)}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: AppDimensions.p12),
            Text(
              '${graded.length}/${submissions.length} değerlendirildi'
              '${graded.isEmpty ? '' : ' • Ortalama ${avg.toStringAsFixed(1)}'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.submission, required this.assignment});

  final SubmissionEntity submission;
  final AssignmentEntity assignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return EduCard(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      onTap: () => _GradeSheet.show(context, submission),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
            child: Text(
              submission.studentName.isNotEmpty ? submission.studentName[0] : '?',
              style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(submission.studentName, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '${submission.fileName} • ${PickedFileInfo.formatBytes(submission.fileSizeBytes)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                Text(
                  '${DateTimeHelper.formatDateTime(submission.submittedAt)}${submission.isLate ? ' • GEÇ (-10)' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: submission.isLate ? AppColors.lateSubmissionOrange : muted,
                    fontWeight: submission.isLate ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.p8),
          submission.isGraded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      submission.finalScore!.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.resolvedGreen),
                    ),
                    if (submission.isLate)
                      Text('ham: ${submission.score!.toStringAsFixed(0)}', style: theme.textTheme.labelSmall),
                  ],
                )
              : const Chip(label: Text('Değerlendir'), visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

/// Puan + yazılı geri bildirim formu.
class _GradeSheet extends StatefulWidget {
  const _GradeSheet({required this.submission});

  final SubmissionEntity submission;

  static Future<void> show(BuildContext context, SubmissionEntity submission) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: BlocProvider.value(
        value: context.read<AssignmentCubit>(),
        child: _GradeSheet(submission: submission),
      ),
    ),
  );

  @override
  State<_GradeSheet> createState() => _GradeSheetState();
}

class _GradeSheetState extends State<_GradeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _scoreController = TextEditingController(
    text: widget.submission.score?.toStringAsFixed(0) ?? '',
  );
  late String _feedback = widget.submission.writtenFeedback ?? '';
  bool _saving = false;

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  double? get _rawScore => double.tryParse(_scoreController.text.replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await context.read<AssignmentCubit>().grade(
        actor: context.currentUser,
        submissionId: widget.submission.id,
        score: _rawScore!,
        writtenFeedback: _feedback,
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('${widget.submission.studentName} değerlendirildi.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final raw = _rawScore;
    final finalScore = raw == null ? null : GradeCalculator.applyLatePenalty(raw, isLate: widget.submission.isLate);

    return Container(
      padding: AppDimensions.paddingAll24,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.submission.studentName} • ${widget.submission.studentNo}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(widget.submission.fileName),
              const SizedBox(height: AppDimensions.p16),
              TextFormField(
                controller: _scoreController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: AppInputFormatters.score,
                validator: Validators.score,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Puan (0-100)', prefixIcon: Icon(Icons.grade_outlined)),
              ),
              if (widget.submission.isLate) ...[
                const SizedBox(height: AppDimensions.p8),
                Text(
                  'Geç teslim: 10 puan ceza uygulanır.'
                  '${finalScore == null ? '' : ' Öğrencinin göreceği puan: ${finalScore.toStringAsFixed(0)}'}',
                  style: const TextStyle(color: AppColors.lateSubmissionOrange, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: AppDimensions.p16),
              AudioWrittenFeedbackBox(
                writtenFeedback: _feedback,
                isInstructor: true,
                onWrittenFeedbackChanged: (v) => _feedback = v,
              ),
              const SizedBox(height: AppDimensions.p20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Kaydediliyor...' : 'Puanı ve Geri Bildirimi Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
