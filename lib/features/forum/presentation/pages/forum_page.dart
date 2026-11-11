import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/presentation/auth_context.dart';
import '../cubit/forum_cubit.dart';
import '../cubit/forum_state.dart';
import '../widgets/ask_question_modal.dart';
import '../widgets/forum_question_card.dart';

/// [ForumPage] Kampüs Forumu: ders etiketli soru-cevap akışı.
class ForumPage extends StatelessWidget {
  const ForumPage({super.key});

  static const List<String> defaultTags = ['Flutter', 'Algoritmalar', 'Mobil Mimari', 'Firebase', 'Genel'];

  static Future<void> openAskQuestion(BuildContext context) {
    final user = context.currentUser;
    final cubit = context.read<ForumCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final tags = {...defaultTags, ...cubit.state.courseTags}.toList();
    return AskQuestionModal.show(
      context,
      courseTags: tags,
      onPickFromGallery: () async {
        final file = await sl<FilePickerService>().pickImage();
        return file == null ? null : (file.path ?? file.name);
      },
      onAskQuestion: ({required courseTag, required topicTag, required questionText, localPhotoPath}) async {
        await cubit.askQuestion(
          actor: user,
          courseTag: courseTag,
          topicTag: topicTag,
          questionText: questionText,
          photoPath: localPhotoPath,
        );
        messenger.showSnackBar(const SnackBar(content: Text('Sorunuz kampüs forumunda yayınlandı.')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForumCubit, ForumState>(
      builder: (context, state) {
        final cubit = context.read<ForumCubit>();
        switch (state.status) {
          case ViewStatus.initial:
          case ViewStatus.loading:
            return const LoadingStateView();
          case ViewStatus.failure:
            return ErrorStateView(message: state.errorMessage, onRetry: cubit.start);
          case ViewStatus.loaded:
            break;
        }
        final questions = state.visibleQuestions;

        return Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
                children: [
                  ChoiceChip(
                    label: Text('Tümü (${state.questions.length})'),
                    selected: state.courseFilter == null,
                    onSelected: (_) => cubit.setCourseFilter(null),
                  ),
                  for (final tag in state.courseTags) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(tag),
                      selected: state.courseFilter == tag,
                      onSelected: (_) => cubit.setCourseFilter(state.courseFilter == tag ? null : tag),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: questions.isEmpty
                  ? EmptyStateView(
                      icon: Icons.forum_outlined,
                      title: 'Henüz soru yok',
                      message: 'Aklındaki soruyu sor; eğitmenler ve arkadaşların yanıtlasın.',
                      actionLabel: 'Soru Sor',
                      onAction: () => openAskQuestion(context),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: questions.length,
                      itemBuilder: (context, i) {
                        final q = questions[i];
                        return ForumQuestionCard(
                          authorName: q.authorName,
                          courseTag: q.courseTag,
                          topicTag: q.topicTag,
                          questionText: q.questionText,
                          isResolved: q.isResolved,
                          hasImage: q.hasImage,
                          answerCount: state.answerCountFor(q.id),
                          createdAt: q.createdAt,
                          onTap: () => Navigator.of(context).pushNamed(RouteNames.forumQuestionDetail, arguments: q.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
