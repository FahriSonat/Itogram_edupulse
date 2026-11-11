import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/widgets/atmosphere/ambient_background.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../auth/presentation/auth_context.dart';
import '../cubit/forum_cubit.dart';
import '../cubit/forum_state.dart';
import '../widgets/forum_question_card.dart';
import '../widgets/instructor_resolved_answer_card.dart';

/// [ForumQuestionDetailPage] soru detayı, cevaplar ve cevap yazma alanı.
/// Eğitmen bir cevabı "çözüm" olarak onaylayabilir.
class ForumQuestionDetailPage extends StatefulWidget {
  const ForumQuestionDetailPage({super.key, required this.questionId});

  final String questionId;

  @override
  State<ForumQuestionDetailPage> createState() => _ForumQuestionDetailPageState();
}

class _ForumQuestionDetailPageState extends State<ForumQuestionDetailPage> {
  final _answerController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ForumCubit>().postAnswer(
        actor: context.currentUser,
        questionId: widget.questionId,
        answerText: text,
      );
      _answerController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(Failure.from(e).message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _markResolved(String answerId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ForumCubit>().markResolved(
        actor: context.currentUser,
        questionId: widget.questionId,
        answerId: answerId,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Cevap çözüm olarak onaylandı.'), backgroundColor: AppColors.resolvedGreen),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(Failure.from(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(title: 'Soru Detayı', currentRole: user.role),
        body: BlocBuilder<ForumCubit, ForumState>(
          builder: (context, state) {
            final q = state.questionById(widget.questionId);
            if (q == null) return const EmptyStateView(icon: Icons.search_off_rounded, title: 'Soru bulunamadı');
            final answers = state.answersFor(q.id)
              ..sort((a, b) {
                // Onaylanmış cevap en üstte
                if (a.isApproved != b.isApproved) return a.isApproved ? -1 : 1;
                return a.createdAt.compareTo(b.createdAt);
              });

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: AppDimensions.p16),
                    children: [
                      ForumQuestionCard(
                        authorName: q.authorName,
                        courseTag: q.courseTag,
                        topicTag: q.topicTag,
                        questionText: q.questionText,
                        isResolved: q.isResolved,
                        hasImage: q.hasImage,
                        answerCount: answers.length,
                        createdAt: q.createdAt,
                      ),
                      if (q.hasImage)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p20),
                          child: Row(
                            children: [
                              const Icon(Icons.image_outlined, size: 16),
                              const SizedBox(width: 6),
                              Expanded(child: Text('Ek: ${q.photoName}', overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      SectionHeader(title: 'Cevaplar (${answers.length})'),
                      if (answers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppDimensions.p20, vertical: AppDimensions.p8),
                          child: Text('Henüz cevap yok. İlk cevabı sen yaz!'),
                        ),
                      for (final a in answers)
                        InstructorResolvedAnswerCard(
                          responderName: a.responderName,
                          responderRole: a.responderRole,
                          answerText: a.answerText,
                          isInstructorApproved: a.isApproved,
                          answeredAt: a.createdAt,
                          canMarkAsResolved: user.isInstructor && !q.isResolved,
                          onMarkAsResolved: () => _markResolved(a.id),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.p16,
                      AppDimensions.p8,
                      AppDimensions.p8,
                      AppDimensions.p8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.dividerLight)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(hintText: 'Cevabını yaz...'),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.p8),
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
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
        ),
      ),
    );
  }
}
