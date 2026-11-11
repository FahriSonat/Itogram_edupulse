import 'package:equatable/equatable.dart';

import '../../../../core/enums/view_status.dart';
import '../../domain/entities/forum_answer_entity.dart';
import '../../domain/entities/forum_question_entity.dart';

class ForumState extends Equatable {
  final ViewStatus status;
  final List<ForumQuestionEntity> questions;
  final List<ForumAnswerEntity> answers;

  /// Ders etiketi filtresi. Null ise tüm sorular.
  final String? courseFilter;
  final String? errorMessage;

  const ForumState({
    this.status = ViewStatus.initial,
    this.questions = const [],
    this.answers = const [],
    this.courseFilter,
    this.errorMessage,
  });

  List<ForumQuestionEntity> get visibleQuestions =>
      courseFilter == null ? questions : questions.where((q) => q.courseTag == courseFilter).toList();

  List<String> get courseTags => {for (final q in questions) q.courseTag}.toList()..sort();

  List<ForumAnswerEntity> answersFor(String questionId) => answers.where((a) => a.questionId == questionId).toList();

  int answerCountFor(String questionId) => answers.where((a) => a.questionId == questionId).length;

  ForumQuestionEntity? questionById(String id) {
    for (final q in questions) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// Eğitmen paneli: çözüm bekleyen soru sayısı.
  int get unresolvedCount => questions.where((q) => !q.isResolved).length;

  ForumState copyWith({
    ViewStatus? status,
    List<ForumQuestionEntity>? questions,
    List<ForumAnswerEntity>? answers,
    String? Function()? courseFilter,
    String? errorMessage,
  }) => ForumState(
    status: status ?? this.status,
    questions: questions ?? this.questions,
    answers: answers ?? this.answers,
    courseFilter: courseFilter != null ? courseFilter() : this.courseFilter,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, questions, answers, courseFilter, errorMessage];
}
