import 'package:equatable/equatable.dart';

/// [ForumQuestionEntity] kampüs forumunda sorulan soru.
class ForumQuestionEntity extends Equatable {
  final String id;
  final String authorUid;
  final String authorName;
  final String courseTag;
  final String topicTag;
  final String questionText;

  /// Ekli fotoğrafın dosya adı (varsa).
  final String? photoName;
  final DateTime createdAt;
  final bool isResolved;
  final String? resolvedAnswerId;

  const ForumQuestionEntity({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.courseTag,
    required this.topicTag,
    required this.questionText,
    this.photoName,
    required this.createdAt,
    this.isResolved = false,
    this.resolvedAnswerId,
  });

  bool get hasImage => photoName != null && photoName!.isNotEmpty;

  ForumQuestionEntity copyWith({bool? isResolved, String? resolvedAnswerId}) => ForumQuestionEntity(
    id: id,
    authorUid: authorUid,
    authorName: authorName,
    courseTag: courseTag,
    topicTag: topicTag,
    questionText: questionText,
    photoName: photoName,
    createdAt: createdAt,
    isResolved: isResolved ?? this.isResolved,
    resolvedAnswerId: resolvedAnswerId ?? this.resolvedAnswerId,
  );

  @override
  List<Object?> get props => [
    id,
    authorUid,
    authorName,
    courseTag,
    topicTag,
    questionText,
    photoName,
    createdAt,
    isResolved,
    resolvedAnswerId,
  ];
}
