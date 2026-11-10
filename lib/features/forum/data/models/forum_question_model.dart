import '../../domain/entities/forum_question_entity.dart';

class ForumQuestionModel extends ForumQuestionEntity {
  const ForumQuestionModel({
    required super.questionId,
    required super.authorUid,
    required super.authorName,
    required super.courseTag,
    required super.topicTag,
    required super.questionText,
    super.imageUrl,
    required super.isResolved,
  });

  factory ForumQuestionModel.fromFirestore(Map<String, dynamic> json, String id) {
    return ForumQuestionModel(
      questionId: id,
      authorUid: json['authorUid'] as String,
      authorName: json['authorName'] as String,
      courseTag: json['courseTag'] as String,
      topicTag: json['topicTag'] as String,
      questionText: json['questionText'] as String,
      imageUrl: json['imageUrl'] as String?,
      isResolved: json['isResolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'courseTag': courseTag,
      'topicTag': topicTag,
      'questionText': questionText,
      'imageUrl': imageUrl,
      'isResolved': isResolved,
    };
  }

  ForumQuestionModel copyWith({
    String? questionId,
    String? authorUid,
    String? authorName,
    String? courseTag,
    String? topicTag,
    String? questionText,
    String? imageUrl,
    bool? isResolved,
  }) {
    return ForumQuestionModel(
      questionId: questionId ?? this.questionId,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      courseTag: courseTag ?? this.courseTag,
      topicTag: topicTag ?? this.topicTag,
      questionText: questionText ?? this.questionText,
      imageUrl: imageUrl ?? this.imageUrl,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}