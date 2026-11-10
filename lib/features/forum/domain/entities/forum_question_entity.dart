import 'package:equatable/equatable.dart';

class ForumQuestionEntity extends Equatable {
  final String questionId;
  final String authorUid;
  final String authorName;
  final String courseTag;
  final String topicTag;
  final String questionText;
  final String? imageUrl;
  final bool isResolved;

  const ForumQuestionEntity({
    required this.questionId,
    required this.authorUid,
    required this.authorName,
    required this.courseTag,
    required this.topicTag,
    required this.questionText,
    this.imageUrl,
    required this.isResolved,
  });

  @override
  List<Object?> get props => [
        questionId,
        authorUid,
        authorName,
        courseTag,
        topicTag,
        questionText,
        imageUrl,
        isResolved,
      ];
}