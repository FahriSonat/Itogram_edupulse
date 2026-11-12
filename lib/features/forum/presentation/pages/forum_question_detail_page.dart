import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../domain/entities/forum_question_entity.dart';
import '../cubit/forum_cubit.dart';
import '../cubit/forum_state.dart';
import '../widgets/instructor_resolved_answer_card.dart';

/// FORUM SORU DETAY VE CEVAPLAMA SAYFASI.
/// 
/// - Sorunun tam metnini, ders/konu etiketlerini ve varsa eklenen fotoğrafı gösterir.
/// - Fotoğrafa dokunulduğunda [Hero] animasyonu ile tam ekran yakınlaştırılabilir ([InteractiveViewer]) açılır.
/// - Sorunun altındaki yanıtlar listelenir.
/// - Eğitmen, doğru olan bir yanıtın yanında "Çözüldü Olarak İşaretle" butonuna basarak
///   soruyu çözüme kavuşturabilir ve cevaba yeşil eğitmen onay rozeti kazandırabilir.
/// - Alt kısımdaki giriş çubuğu üzerinden öğrenciler ve eğitmenler anında yanıt yazabilir.
class ForumQuestionDetailPage extends StatelessWidget {
  const ForumQuestionDetailPage({super.key, required this.questionId});

  final String questionId;

  /// Hero animasyonu için benzersiz görsel etiketi üretir.
  static String heroTagFor(String questionId) => 'forum_image_$questionId';

  /// Soru görselini tam ekran, siyah yarı saydam zemin üzerinde ve yakınlaştırılabilir açar.
  static Future<void> openImage(BuildContext context, String questionId, String imageUrl) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, _, _) => GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Hero(
              tag: heroTagFor(questionId),
              child: InteractiveViewer(child: Image.network(imageUrl, fit: BoxFit.contain)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Soru ID'sine ait detay ve yanıtları izleyen ForumCubit başlatılır
    return BlocProvider<ForumCubit>(
      create: (_) => GetIt.instance<ForumCubit>()
        ..start()
        ..openQuestion(questionId),
      child: _DetailView(questionId: questionId),
    );
  }
}

/// Soru başlığı, yanıt listesi ve altta sabit duran yanıt yazma çubuğu.
class _DetailView extends StatefulWidget {
  const _DetailView({required this.questionId});

  final String questionId;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  // Yanıt metni giriş kontrolcüsü
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  /// Yazılan yanıtı backend'e iletir ve giriş alanını temizler.
  Future<void> _send() async {
    final user = context.readCurrentUser();
    if (user == null || _answerController.text.trim().isEmpty) return;

    final ok = await context.read<ForumCubit>().postAnswer(
          questionId: widget.questionId,
          responderName: user.fullName,
          responderRole: user.role,
          answerText: _answerController.text,
        );

    if (ok && mounted) {
      _answerController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.currentRole;

    return BlocConsumer<ForumCubit, ForumState>(
      listenWhen: (p, c) => c.actionMessage != null && p.actionMessage != c.actionMessage,
      listener: (context, state) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.actionMessage!))),
      builder: (context, state) {
        final cubit = context.read<ForumCubit>();

        // Hata ve yüklenme durumları
        if (state.status == ViewStatus.failure) return ErrorStateView(message: state.errorMessage, onRetry: cubit.start);
        if (state.status.isLoading) return const LoadingStateView(message: 'Soru yükleniyor...');

        final question = state.openQuestion;
        if (question == null) {
          return const EmptyStateView(title: 'Soru bulunamadı', icon: Icons.search_off_rounded);
        }

        return Column(
          children: [
            // Soru ve Yanıtların kaydırılabilir listesi
            Expanded(
              child: ListView(
                padding: AppDimensions.paddingAll16,
                children: [
                  // Soru Başlığı, etiketleri ve varsa görseli
                  _QuestionHeader(question: question),
                  const SizedBox(height: AppDimensions.p16),

                  // Yanıtlar Bölümü Başlığı
                  Text('Yanıtlar (${state.answers.length})', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppDimensions.p8),

                  // Yanıtların yüklenme veya listelenme durumu
                  if (state.answersStatus.isLoading)
                    const Padding(padding: AppDimensions.paddingAll16, child: Center(child: CircularProgressIndicator()))
                  else if (state.answers.isEmpty)
                    const Padding(padding: AppDimensions.paddingAll16, child: Text('Henüz yanıt yok.'))
                  else
                    for (final a in state.answers) ...[
                      InstructorResolvedAnswerCard(
                        key: ValueKey<String>('answer_${a.answerId}'),
                        responderName: a.responderName,
                        responderRole: UserRoleX.fromJson(a.responderRole),
                        answerText: a.answerText,
                        answeredAt: DateTime.now(),
                        isInstructorApproved: a.isInstructorApproved,
                        // Yalnızca eğitmen ve soru henüz çözülmemişse butonu aktif yap
                        canMarkAsResolved: role == UserRole.instructor && !question.isResolved,
                        onMarkAsResolved: () =>
                            cubit.markResolved(questionId: question.questionId, answerId: a.answerId, role: role),
                      ),
                      const SizedBox(height: AppDimensions.p12),
                    ],
                ],
              ),
            ),

            // Ekranın altında sabit duran yanıt yazma alanı
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppDimensions.p16, AppDimensions.p8, AppDimensions.p8, AppDimensions.p8),
                child: Row(
                  children: [
                    // Yanıt giriş alanı
                    Expanded(
                      child: TextField(
                        key: const Key('forum_answer_field'),
                        controller: _answerController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(hintText: 'Yanıtını yaz...'),
                      ),
                    ),
                    // Yanıtı gönder butonu
                    IconButton.filled(
                      key: const Key('forum_answer_send'),
                      onPressed: state.isSubmitting ? null : _send,
                      icon: const Icon(Icons.send_rounded),
                      tooltip: 'Gönder',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Sorunun metnini, yazarını, rozetlerini ve tıklanabilir fotoğrafını gösteren başlık kartı.
class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.question});

  final ForumQuestionEntity question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = question.imageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Geri Dön Butonu ve Ders/Konu Etiket Çipleri
        Row(
          children: [
            if (Navigator.canPop(context))
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Geri',
              ),
            Expanded(
              child: Wrap(
                spacing: AppDimensions.p8,
                runSpacing: AppDimensions.p4,
                children: [
                  Chip(label: Text(question.courseTag)),
                  if (question.topicTag.isNotEmpty) Chip(label: Text(question.topicTag)),
                  if (question.isResolved)
                    const Chip(
                      avatar: Icon(Icons.check_circle_rounded, color: AppColors.resolvedGreen, size: 18),
                      label: Text('Çözüldü'),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.p8),

        // Soru Metni
        Text(question.questionText, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppDimensions.p4),

        // Soran Kişinin Adı
        Text('Soran: ${question.authorName}', style: theme.textTheme.bodySmall),

        // Soruya eklenmiş bir görsel varsa tıklanabilir Hero önizlemesi
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.p12),
          GestureDetector(
            onTap: () => ForumQuestionDetailPage.openImage(context, question.questionId, imageUrl),
            child: Hero(
              tag: ForumQuestionDetailPage.heroTagFor(question.questionId),
              child: ClipRRect(
                borderRadius: AppDimensions.radius16,
                child: Image.network(
                  imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(height: 120, child: Center(child: Icon(Icons.broken_image))),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
