import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/view_status.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/forum_answer_entity.dart';
import '../../domain/entities/forum_question_entity.dart';
import '../../domain/usecases/ask_question_with_photo_usecase.dart';
import '../../domain/usecases/mark_answer_as_resolved_usecase.dart';
import '../../domain/usecases/post_forum_answer_usecase.dart';
import '../../domain/usecases/watch_forum_questions_usecase.dart';
import 'forum_state.dart';

class ForumCubit extends Cubit<ForumState> {
  ForumCubit({
    required this._watchQuestions,
    required this._askQuestion,
    required this._postAnswer,
    required this._markResolved,
  }) : super(const ForumState()) {
    start();
  }

  final WatchForumQuestionsUseCase _watchQuestions;
  final AskQuestionWithPhotoUseCase _askQuestion;
  final PostForumAnswerUseCase _postAnswer;
  final MarkAnswerAsResolvedUseCase _markResolved;

  StreamSubscription<List<ForumQuestionEntity>>? _questionSub;
  StreamSubscription<List<ForumAnswerEntity>>? _answerSub;

  void start() {
    emit(state.copyWith(status: ViewStatus.loading));
    _questionSub?.cancel();
    _answerSub?.cancel();
    _questionSub = _watchQuestions().listen(
      (q) => emit(state.copyWith(status: ViewStatus.loaded, questions: q)),
      onError: _onError,
    );
    _answerSub = _watchQuestions.answers().listen((a) => emit(state.copyWith(answers: a)), onError: _onError);
  }

  void _onError(Object e) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: Failure.from(e).message));

  void setCourseFilter(String? courseTag) => emit(state.copyWith(courseFilter: () => courseTag));

  Future<void> askQuestion({
    required UserEntity actor,
    required String courseTag,
    required String topicTag,
    required String questionText,
    String? photoPath,
  }) => _askQuestion(
    actor: actor,
    courseTag: courseTag,
    topicTag: topicTag,
    questionText: questionText,
    photoPath: photoPath,
  );

  Future<void> postAnswer({required UserEntity actor, required String questionId, required String answerText}) =>
      _postAnswer(actor: actor, questionId: questionId, answerText: answerText);

  Future<void> markResolved({required UserEntity actor, required String questionId, required String answerId}) =>
      _markResolved(actor: actor, questionId: questionId, answerId: answerId);

  @override
  Future<void> close() {
    _questionSub?.cancel();
    _answerSub?.cancel();
    return super.close();
  }
}
