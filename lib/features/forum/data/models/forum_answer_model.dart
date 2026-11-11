import '../../../../core/enums/user_role.dart';
import '../../domain/entities/forum_answer_entity.dart';

class ForumAnswerModel extends ForumAnswerEntity {
  const ForumAnswerModel({
    required super.id,
    required super.questionId,
    required super.responderUid,
    required super.responderName,
    required super.responderRole,
    required super.answerText,
    required super.createdAt,
    super.isApproved,
  });

  factory ForumAnswerModel.fromEntity(ForumAnswerEntity e) => ForumAnswerModel(
    id: e.id,
    questionId: e.questionId,
    responderUid: e.responderUid,
    responderName: e.responderName,
    responderRole: e.responderRole,
    answerText: e.answerText,
    createdAt: e.createdAt,
    isApproved: e.isApproved,
  );

  factory ForumAnswerModel.fromJson(Map<String, dynamic> json) => ForumAnswerModel(
    id: json['id'] as String,
    questionId: json['questionId'] as String? ?? '',
    responderUid: json['responderUid'] as String? ?? '',
    responderName: json['responderName'] as String? ?? '',
    responderRole: UserRole.fromJson(json['responderRole'] as String?),
    answerText: json['answerText'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    isApproved: json['isApproved'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionId': questionId,
    'responderUid': responderUid,
    'responderName': responderName,
    'responderRole': responderRole.toJson(),
    'answerText': answerText,
    'createdAt': createdAt.toIso8601String(),
    'isApproved': isApproved,
  };
}
