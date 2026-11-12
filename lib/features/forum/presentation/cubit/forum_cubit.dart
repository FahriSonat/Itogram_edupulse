import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/enums/view_status.dart';
import '../../domain/entities/forum_question_entity.dart';
import '../../domain/usecases/ask_question_with_photo_usecase.dart';
import '../../domain/usecases/mark_answer_as_resolved_usecase.dart';
import '../../domain/usecases/post_forum_answer_usecase.dart';
import '../../domain/usecases/watch_forum_questions_usecase.dart';
import 'forum_state.dart';

/// Etiket filtrelemesini, soru fotoğrafı yükleme durumunu, yanıt akışını ve
/// "Çözüldü" sabitleme aksiyonunu yönetir.
class ForumCubit extends Cubit<ForumState> {
  ForumCubit({
    required this.watchForumQuestionsUseCase,
    required this.askQuestionWithPhotoUseCase,
    required this.postForumAnswerUseCase,
    required this.markAnswerAsResolvedUseCase,
  }) : super(const ForumState());

  final WatchForumQuestionsUseCase watchForumQuestionsUseCase;
  final AskQuestionWithPhotoUseCase askQuestionWithPhotoUseCase;
  final PostForumAnswerUseCase postForumAnswerUseCase;
  final MarkAnswerAsResolvedUseCase markAnswerAsResolvedUseCase;

  StreamSubscription<dynamic>? _questionsSub;
  StreamSubscription<dynamic>? _answersSub;
  final Map<String, StreamSubscription<dynamic>> _answerCountSubs =
      <String, StreamSubscription<dynamic>>{};

  void start() => _watchQuestions();

  void _watchQuestions() {
    emit(state.copyWith(status: ViewStatus.loading));
    _questionsSub?.cancel();
    _questionsSub = watchForumQuestionsUseCase(courseTag: state.courseTag, topicTag: state.topicTag).listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: failure.message)),
        (questions) {
          emit(state.copyWith(status: ViewStatus.loaded, questions: questions));
          _watchAnswerCounts(questions);
        },
      );
    });
  }

  void _watchAnswerCounts(List<ForumQuestionEntity> questions) {
    final activeIds = questions.map((q) => q.questionId).toSet();
    final removedIds =
        _answerCountSubs.keys.where((id) => !activeIds.contains(id)).toList();
    for (final id in removedIds) {
      _answerCountSubs.remove(id)?.cancel();
    }
    for (final q in questions) {
      final id = q.questionId;
      if (id.isEmpty || _answerCountSubs.containsKey(id)) continue;
      _answerCountSubs[id] = watchForumQuestionsUseCase.answers(id).listen((res) {
        res.fold(
          (_) {},
          (list) {
            final nextCounts = Map<String, int>.of(state.answerCounts)
              ..[id] = list.length;
            emit(state.copyWith(answerCounts: nextCounts));
          },
        );
      });
    }
  }

  /// Ders etiketine göre filtreler (null = tüm sorular).
  void filterByCourse(String? courseTag) {
    emit(courseTag == null ? state.copyWith(clearCourseTag: true) : state.copyWith(courseTag: courseTag));
    _watchQuestions();
  }

  Future<bool> askQuestion({
    required String authorUid,
    required String authorName,
    required String courseTag,
    required String topicTag,
    required String questionText,
    String? localPhotoPath,
  }) async {
    emit(state.copyWith(isSubmitting: true));
    final result = await askQuestionWithPhotoUseCase(
      authorUid: authorUid,
      authorName: authorName,
      courseTag: courseTag,
      topicTag: topicTag,
      questionText: questionText,
      localPhotoPath: localPhotoPath,
    );
    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(isSubmitting: false, actionMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(isSubmitting: false, actionMessage: 'Sorunuz yayınlandı.'));
        return true;
      },
    );
  }

  /// Soru detayına girildiğinde yanıtları canlı izler.
  void openQuestion(String questionId) {
    emit(state.copyWith(openQuestionId: questionId, answers: const [], answersStatus: ViewStatus.loading));
    _answersSub?.cancel();
    _answersSub = watchForumQuestionsUseCase.answers(questionId).listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(answersStatus: ViewStatus.failure, errorMessage: failure.message)),
        (answers) => emit(state.copyWith(answersStatus: ViewStatus.loaded, answers: answers)),
      );
    });
  }

  Future<bool> postAnswer({
    required String questionId,
    required String responderName,
    required UserRole responderRole,
    required String answerText,
  }) async {
    emit(state.copyWith(isSubmitting: true));
    final result = await postForumAnswerUseCase(
      questionId: questionId,
      responderName: responderName,
      responderRole: responderRole,
      answerText: answerText,
    );
    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(isSubmitting: false, actionMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(isSubmitting: false));
        return true;
      },
    );
  }

  /// Yalnızca eğitmen: yanıtı onaylar ve soruyu "Çözüldü" yapar.
  Future<void> markResolved({required String questionId, required String answerId, required UserRole role}) async {
    final result = await markAnswerAsResolvedUseCase(questionId: questionId, answerId: answerId, role: role);
    emit(state.copyWith(actionMessage: result.fold((f) => f.message, (_) => 'Cevap "Çözüldü" olarak işaretlendi.')));
  }

  @override
  Future<void> close() {
    _questionsSub?.cancel();
    _answersSub?.cancel();
    for (final sub in _answerCountSubs.values) {
      sub.cancel();
    }
    _answerCountSubs.clear();
    return super.close();
  }
}
