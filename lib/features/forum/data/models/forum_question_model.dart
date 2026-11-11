import '../../domain/entities/forum_question_entity.dart';

class ForumQuestionModel extends ForumQuestionEntity {
  const ForumQuestionModel({
    required super.id,
    required super.authorUid,
    required super.authorName,
    required super.courseTag,
    required super.topicTag,
    required super.questionText,
    super.photoName,
    required super.createdAt,
    super.isResolved,
    super.resolvedAnswerId,
  });

  factory ForumQuestionModel.fromEntity(ForumQuestionEntity e) => ForumQuestionModel(
    id: e.id,
    authorUid: e.authorUid,
    authorName: e.authorName,
    courseTag: e.courseTag,
    topicTag: e.topicTag,
    questionText: e.questionText,
    photoName: e.photoName,
    createdAt: e.createdAt,
    isResolved: e.isResolved,
    resolvedAnswerId: e.resolvedAnswerId,
  );

  factory ForumQuestionModel.fromJson(Map<String, dynamic> json) => ForumQuestionModel(
    id: json['id'] as String,
    authorUid: json['authorUid'] as String? ?? '',
    authorName: json['authorName'] as String? ?? '',
    courseTag: json['courseTag'] as String? ?? 'Genel',
    topicTag: json['topicTag'] as String? ?? 'Genel',
    questionText: json['questionText'] as String? ?? '',
    photoName: json['photoName'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    isResolved: json['isResolved'] as bool? ?? false,
    resolvedAnswerId: json['resolvedAnswerId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorUid': authorUid,
    'authorName': authorName,
    'courseTag': courseTag,
    'topicTag': topicTag,
    'questionText': questionText,
    'photoName': photoName,
    'createdAt': createdAt.toIso8601String(),
    'isResolved': isResolved,
    'resolvedAnswerId': resolvedAnswerId,
  };
}
