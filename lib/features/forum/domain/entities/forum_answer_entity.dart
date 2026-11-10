import 'package:equatable/equatable.dart';

class ForumAnswerEntity extends Equatable {
  final String answerId;
  final String responderName;
  final String responderRole;
  final String answerText;
  final bool isInstructorApproved;

  const ForumAnswerEntity({
    required this.answerId,
    required this.responderName,
    required this.responderRole,
    required this.answerText,
    required this.isInstructorApproved,
  });

  @override
  List<Object?> get props => [
        answerId,
        responderName,
        responderRole,
        answerText,
        isInstructorApproved,
      ];
}