import 'package:equatable/equatable.dart';

import '../../../../core/enums/view_status.dart';
import '../../domain/entities/forum_answer_entity.dart';
import '../../domain/entities/forum_question_entity.dart';

class ForumState extends Equatable {
  const ForumState({
    this.status = ViewStatus.initial,
    this.questions = const <ForumQuestionEntity>[],
    this.courseTag,
    this.topicTag,
    this.openQuestionId,
    this.answers = const <ForumAnswerEntity>[],
    this.answerCounts = const <String, int>{},
    this.answersStatus = ViewStatus.initial,
    this.isSubmitting = false,
    this.errorMessage,
    this.actionMessage,
  });

  final ViewStatus status;
  final List<ForumQuestionEntity> questions;

  /// Etiket filtreleri (null = tümü).
  final String? courseTag;
  final String? topicTag;

  final String? openQuestionId;
  final List<ForumAnswerEntity> answers;
  final Map<String, int> answerCounts;
  final ViewStatus answersStatus;
  final bool isSubmitting;
  final String? errorMessage;
  final String? actionMessage;

  ForumQuestionEntity? get openQuestion {
    for (final q in questions) {
      if (q.questionId == openQuestionId) return q;
    }
    return null;
  }

  /// Filtre çipleri için mevcut ders etiketleri.
  List<String> get availableCourseTags =>
      (questions.map((q) => q.courseTag).where((t) => t.isNotEmpty).toSet().toList()..sort());

  ForumState copyWith({
    ViewStatus? status,
    List<ForumQuestionEntity>? questions,
    String? courseTag,
    String? topicTag,
    bool clearCourseTag = false,
    bool clearTopicTag = false,
    String? openQuestionId,
    List<ForumAnswerEntity>? answers,
    Map<String, int>? answerCounts,
    ViewStatus? answersStatus,
    bool? isSubmitting,
    String? errorMessage,
    String? actionMessage,
  }) {
    return ForumState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      courseTag: clearCourseTag ? null : (courseTag ?? this.courseTag),
      topicTag: clearTopicTag ? null : (topicTag ?? this.topicTag),
      openQuestionId: openQuestionId ?? this.openQuestionId,
      answers: answers ?? this.answers,
      answerCounts: answerCounts ?? this.answerCounts,
      answersStatus: answersStatus ?? this.answersStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        questions,
        courseTag,
        topicTag,
        openQuestionId,
        answers,
        answerCounts,
        answersStatus,
        isSubmitting,
        errorMessage,
        actionMessage,
      ];
}
