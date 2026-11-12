import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/role_visibility_guard.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../domain/entities/submission_entity.dart';
import '../../domain/usecases/grade_and_feedback_usecase.dart';
import '../cubit/assignment_cubit.dart';
import '../cubit/assignment_state.dart';
import '../widgets/audio_written_feedback_box.dart';
import '../widgets/late_submission_warning_banner.dart';

/// ÖDEV DEĞERLENDİRME & GERİ BİLDİRİM SAYFASI (Yalnızca Eğitmen).
/// 
/// Eğitmenin teslim edilen öğrenci dosyasını incelemesini, 100 üzerinden not vermesini,
/// yazılı ve sesli geri bildirim kaydetmesini sağlayan ekrandır.
/// 
/// Kural 2 (Gecikmiş Teslim Cezası):
/// - Eğer öğrenci ödevi son teslim tarihinden sonra yüklediyse sistemde `isLatePenaltyApplied`
///   bayrağı aktiftir. Eğitmenin girdiği ham puandan (rawScore) otomatik olarak 10 ceza puanı
///   düşülerek nihai puan (finalScore) önizlemede canlı olarak gösterilir ve kaydedilir.
/// 
/// Güvenlik:
/// - [RoleVisibilityGuard.onlyInstructor] ile öğrenci erişimi UI seviyesinde engellenir.
class SubmissionGradingDetailPage extends StatelessWidget {
  const SubmissionGradingDetailPage({super.key, required this.submissionId, required this.assignmentId});

  final String submissionId;
  final String assignmentId;

  @override
  Widget build(BuildContext context) {
    // Öğrenci bu ekrana erişmeye çalışırsa Yetkisiz Erişim uyarısı gösterilir
    return RoleVisibilityGuard.onlyInstructor(
      currentRole: context.currentRole,
      fallback: const EmptyStateView(
        title: 'Yetkisiz erişim',
        message: 'Bu sayfa yalnızca eğitmenler içindir.',
        icon: Icons.lock_outline_rounded,
      ),
      // İlgili ödevin verilerini çekmek için AssignmentCubit inject edilir
      child: BlocProvider<AssignmentCubit>(
        create: (_) => GetIt.instance<AssignmentCubit>()..openAssignment(assignmentId),
        child: _GradingView(submissionId: submissionId, assignmentId: assignmentId),
      ),
    );
  }
}

/// Değerlendirme ana görünümü: Teslim durum kontrolü ve hata/yükleniyor ekranları.
class _GradingView extends StatelessWidget {
  const _GradingView({required this.submissionId, required this.assignmentId});

  final String submissionId;
  final String assignmentId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssignmentCubit, AssignmentState>(
      listenWhen: (p, c) => c.actionMessage != null && p.actionMessage != c.actionMessage,
      listener: (context, state) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.actionMessage!))),
      builder: (context, state) {
        final cubit = context.read<AssignmentCubit>();

        // Teslim verileri yüklenirken hata oluşursa gösterilen görünüm
        if (state.submissionsStatus == ViewStatus.failure) {
          return ErrorStateView(message: state.errorMessage, onRetry: () => cubit.openAssignment(assignmentId));
        }

        // Veriler getirilirken yükleniyor durumu
        if (state.submissionsStatus.isLoading) return const LoadingStateView(message: 'Teslim yükleniyor...');

        // Değerlendirilecek teslim ID eşleşmesi
        final submission = state.submissionById(submissionId);
        if (submission == null) {
          return const EmptyStateView(title: 'Teslim bulunamadı', icon: Icons.search_off_rounded);
        }

        // Teslim bulunduysa notlandırma formunu aç
        return _GradingForm(submission: submission, assignmentId: assignmentId, state: state);
      },
    );
  }
}

/// Not, yazılı geribildirim ve ses kaydını içeren form bileşeni.
class _GradingForm extends StatefulWidget {
  const _GradingForm({required this.submission, required this.assignmentId, required this.state});

  final SubmissionEntity submission;
  final String assignmentId;
  final AssignmentState state;

  @override
  State<_GradingForm> createState() => _GradingFormState();
}

class _GradingFormState extends State<_GradingForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Eğitmenin girdiği ham not (0-100) kontrolcüsü
  late final TextEditingController _scoreController =
      TextEditingController(text: widget.submission.rawScore?.toStringAsFixed(0) ?? '');

  // Yazılı geri bildirim metni
  late String _feedback = widget.submission.writtenFeedback ?? '';

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  /// Metin kutusundan ondalıklı puanı parse eder.
  double? get _rawScore => double.tryParse(_scoreController.text.replaceAll(',', '.'));

  /// Formu onaylar ve notu/ses kaydını kaydetmek üzere Cubit fonksiyonunu çağırır.
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await context.read<AssignmentCubit>().gradeSubmission(
          assignmentId: widget.assignmentId,
          submissionId: widget.submission.submissionId,
          rawScore: _rawScore!,
          writtenFeedback: _feedback,
        );
    if (ok && mounted) await Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.submission;
    final state = widget.state;
    final cubit = context.read<AssignmentCubit>();
    final raw = _rawScore;

    // Kural 2: Ham puandan gecikme cezası (-10) düşülerek hesaplanan canlı önizleme
    final preview = raw == null ? null : GradeAndFeedbackUseCase.previewFinalScore(raw, isLate: s.isLatePenaltyApplied);

    return Form(
      key: _formKey,
      child: ListView(
        padding: AppDimensions.paddingAll16,
        children: [
          // Sayfa Üst Barı ve Geri Butonu
          Row(
            children: [
              if (Navigator.canPop(context))
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Geri',
                ),
              Expanded(
                child: Text('Ödev Notlandırma', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p12),

          // Öğrenci Bilgi Kartı
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_rounded),
              title: Text(s.studentName),
              subtitle: Text('Teslim: ${_fmt(s.submittedAt)} · ${s.status.name}'),
            ),
          ),

          // Teslim Edilen Dosya Kartı (URL panoya kopyalanabilir)
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_file_rounded),
              title: Text(s.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(s.fileUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                tooltip: 'Bağlantıyı kopyala',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: s.fileUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dosya bağlantısı kopyalandı.')));
                  }
                },
              ),
            ),
          ),

          // Gecikmiş teslim ise -10 ceza puanı uyarı bandı
          if (s.isLatePenaltyApplied) ...[
            const SizedBox(height: AppDimensions.p8),
            const LateSubmissionWarningBanner(),
          ],
          const SizedBox(height: AppDimensions.p16),

          // Puan Giriş Alanı (0-100 arası kısıtlı ve formatlı)
          TextFormField(
            key: const Key('grading_score'),
            controller: _scoreController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [GradeInputFormatter()],
            validator: Validators.grade,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Puan (0-100)',
              prefixIcon: Icon(Icons.grade_rounded),
            ),
          ),

          // Cezalı / Cezasız nihai puan canlı önizleme metni
          if (preview != null) ...[
            const SizedBox(height: AppDimensions.p8),
            Text(
              s.isLatePenaltyApplied
                  ? 'Öğrencinin göreceği puan: ${preview.toStringAsFixed(0)} (-10 gecikme cezası)'
                  : 'Öğrencinin göreceği puan: ${preview.toStringAsFixed(0)}',
              key: const Key('grading_preview'),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: AppDimensions.p16),

          // Sesli ve Yazılı Geri Bildirim Kutusu (Ses kaydı başlatma / dinleme)
          AudioWrittenFeedbackBox(
            isInstructor: true,
            writtenFeedback: _feedback,
            audioFeedbackUrl: state.recordedAudioPath ?? s.audioFeedbackUrl,
            isRecording: state.isRecording,
            onWrittenFeedbackChanged: (v) => _feedback = v,
            onStartRecording: cubit.startRecording,
            onStopRecording: cubit.stopRecording,
            onDeleteAudio: cubit.discardRecording,
            onPlayAudio: ((state.recordedAudioPath ?? s.audioFeedbackUrl) ?? '').isNotEmpty
                ? () => cubit.playAudioFeedback(state.recordedAudioPath ?? s.audioFeedbackUrl)
                : null,
          ),
          const SizedBox(height: AppDimensions.p24),

          // Puanı ve Geri Bildirimleri Kaydet Butonu
          FilledButton.icon(
            key: const Key('grading_save'),
            onPressed: state.isGrading ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: state.isGrading
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.save_rounded),
            label: const Text('Puanı Kaydet'),
          ),
        ],
      ),
    );
  }

  /// Tarih ve saat formatlayıcı yardımcı fonksiyon.
  static String _fmt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
