import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../../../core/widgets/role_visibility_guard.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../announcements/presentation/cubit/announcement_cubit.dart';
import '../../../announcements/presentation/widgets/crisis_broadcast_bottom_sheet.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../../schedule/presentation/cubit/schedule_cubit.dart';
import '../cubit/forum_cubit.dart';
import '../cubit/forum_state.dart';
import '../widgets/ask_question_modal.dart';
import '../widgets/forum_question_card.dart';
import 'forum_question_detail_page.dart';

/// 2.6 FORUM: ders/konu etiketli soru akışı ve fotoğraflı "Soru Sor".
/// Eğitmen üstte hızlı "Anlık Kriz Yayını" erişimini görür.
class ForumPage extends StatelessWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sl = GetIt.instance;
    return MultiBlocProvider(
      providers: [
        BlocProvider<ForumCubit>(create: (_) => sl<ForumCubit>()..start()),
        BlocProvider<ScheduleCubit>(create: (_) => sl<ScheduleCubit>()..start()),
      ],
      child: const _ForumView(),
    );
  }
}

class _ForumView extends StatelessWidget {
  const _ForumView();

  /// Ders etiketleri program kodlarından gelir (filtreleme sonrası kaybolmaz).
  List<String> _courseTags(BuildContext context) {
    final tags = context.watch<ScheduleCubit>().state.courses.map((c) => c.courseCode).toSet().toList()..sort();
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final role = context.currentRole;
    final tags = _courseTags(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('forum_ask'),
        onPressed: () => _openAsk(context, tags),
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Soru Sor'),
      ),
      body: BlocConsumer<ForumCubit, ForumState>(
        listenWhen: (p, c) => c.actionMessage != null && p.actionMessage != c.actionMessage,
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.actionMessage!))),
        builder: (context, state) {
          final cubit = context.read<ForumCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoleVisibilityGuard.onlyInstructor(
                currentRole: role,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.p16, AppDimensions.p12, AppDimensions.p16, 0),
                  child: OutlinedButton.icon(
                    key: const Key('forum_crisis'),
                    onPressed: () => _openCrisis(context),
                    icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    label: const Text('Anlık Kriz Yayını'),
                  ),
                ),
              ),
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: AppDimensions.paddingH16V8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tümü'),
                      selected: state.courseTag == null,
                      onSelected: (_) => cubit.filterByCourse(null),
                    ),
                    for (final t in tags) ...[
                      const SizedBox(width: AppDimensions.p8),
                      ChoiceChip(
                        label: Text(t),
                        selected: state.courseTag == t,
                        onSelected: (_) => cubit.filterByCourse(state.courseTag == t ? null : t),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(child: _list(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _list(BuildContext context, ForumState state) {
    final cubit = context.read<ForumCubit>();
    if (state.status.isLoading) return const LoadingStateView(message: 'Sorular yükleniyor...');
    if (state.status == ViewStatus.failure) return ErrorStateView(message: state.errorMessage, onRetry: cubit.start);
    if (state.questions.isEmpty) {
      return const EmptyStateView(
        title: 'Henüz soru yok',
        message: 'Anlamadığın bir konu mu var? İlk soruyu sen sor!',
        icon: Icons.forum_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppDimensions.p16, AppDimensions.p8, AppDimensions.p16, 96),
      itemCount: state.questions.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.p12),
      itemBuilder: (context, i) {
        final q = state.questions[i];
        final hasImage = (q.imageUrl ?? '').isNotEmpty;
        return ForumQuestionCard(
          key: ValueKey<String>('question_${q.questionId}'),
          authorName: q.authorName,
          courseTag: q.courseTag,
          topicTag: q.topicTag,
          questionText: q.questionText,
          createdAt: DateTime.now(),
          answerCount: state.answerCounts[q.questionId] ?? 0,
          isResolved: q.isResolved,
          hasImage: hasImage,
          imageUrl: q.imageUrl,
          heroTag: ForumQuestionDetailPage.heroTagFor(q.questionId),
          onTap: () => context.push(RouteNames.forumQuestionPath(q.questionId)),
          onImageTap: hasImage ? () => ForumQuestionDetailPage.openImage(context, q.questionId, q.imageUrl!) : null,
        );
      },
    );
  }

  static Future<void> _openAsk(BuildContext context, List<String> tags) {
    final cubit = context.read<ForumCubit>();
    final user = context.readCurrentUser();
    final picker = GetIt.instance<FilePickerService>();
    return AskQuestionModal.show(
      context,
      courseTags: tags.isEmpty ? const ['Genel'] : tags,
      topicSuggestions: const ['Vize', 'Final', 'Ödev', 'Proje', 'Laboratuvar'],
      onPickFromCamera: () async => (await picker.pickImage(source: ImageSource.camera))?.path,
      onPickFromGallery: () async => (await picker.pickImage())?.path,
      onAskQuestion: ({
        required String courseTag,
        required String topicTag,
        required String questionText,
        String? localPhotoPath,
      }) async {
        if (user == null) return;
        await cubit.askQuestion(
          authorUid: user.uid,
          authorName: user.fullName,
          courseTag: courseTag,
          topicTag: topicTag,
          questionText: questionText,
          localPhotoPath: localPhotoPath,
        );
      },
    );
  }

  /// Eğitmenin forumdan hızlı kriz yayını: Ana Sayfa ile aynı AnnouncementCubit akışı.
  static Future<void> _openCrisis(BuildContext context) async {
    final courses = context.read<ScheduleCubit>().state.courses;
    final targets = <String, String>{
      'all': 'Tüm Kampüs',
      for (final c in courses) c.courseId: '${c.courseCode} · ${c.courseName}',
    };
    final messenger = ScaffoldMessenger.of(context);
    final announcements = GetIt.instance<AnnouncementCubit>();
    try {
      await CrisisBroadcastBottomSheet.show(
        context,
        targets: targets,
        onBroadcast: ({
          required String targetId,
          required String targetLabel,
          required String title,
          required String message,
        }) async {
          await announcements.sendCrisisBroadcast(
            title: title,
            message: message,
            targetCourseId: targetId == 'all' ? null : targetId,
          );
          messenger.showSnackBar(SnackBar(content: Text('Kriz yayını gönderildi: $targetLabel')));
        },
      );
    } finally {
      await announcements.close();
    }
  }
}
