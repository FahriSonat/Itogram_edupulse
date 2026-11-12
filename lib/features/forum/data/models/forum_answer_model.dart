import '../../domain/entities/forum_answer_entity.dart';

class ForumAnswerModel extends ForumAnswerEntity {
  const ForumAnswerModel({
    required super.answerId,
    required super.responderName,
    required super.responderRole,
    required super.answerText,
    required super.isInstructorApproved,
  });

  factory ForumAnswerModel.fromFirestore(Map<String, dynamic> json, String id) {
    return ForumAnswerModel(
      answerId: id,
      responderName: (json['responderName'] ?? '').toString(),
      responderRole: (json['responderRole'] ?? '').toString(),
      answerText: (json['answerText'] ?? '').toString(),
      isInstructorApproved: json['isInstructorApproved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responderName': responderName,
      'responderRole': responderRole,
      'answerText': answerText,
      'isInstructorApproved': isInstructorApproved,
    };
  }

  ForumAnswerModel copyWith({
    String? answerId,
    String? responderName,
    String? responderRole,
    String? answerText,
    bool? isInstructorApproved,
  }) {
    return ForumAnswerModel(
      answerId: answerId ?? this.answerId,
      responderName: responderName ?? this.responderName,
      responderRole: responderRole ?? this.responderRole,
      answerText: answerText ?? this.answerText,
      isInstructorApproved: isInstructorApproved ?? this.isInstructorApproved,
    );
  }
}