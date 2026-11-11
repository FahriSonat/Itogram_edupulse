import 'package:equatable/equatable.dart';

import '../../../../core/enums/user_role.dart';

/// [ForumAnswerEntity] bir foruma verilen cevap.
class ForumAnswerEntity extends Equatable {
  final String id;
  final String questionId;
  final String responderUid;
  final String responderName;
  final UserRole responderRole;
  final String answerText;
  final DateTime createdAt;

  /// Eğitmen tarafından "çözüm" olarak onaylandı mı?
  final bool isApproved;

  const ForumAnswerEntity({
    required this.id,
    required this.questionId,
    required this.responderUid,
    required this.responderName,
    required this.responderRole,
    required this.answerText,
    required this.createdAt,
    this.isApproved = false,
  });

  ForumAnswerEntity copyWith({bool? isApproved}) => ForumAnswerEntity(
    id: id,
    questionId: questionId,
    responderUid: responderUid,
    responderName: responderName,
    responderRole: responderRole,
    answerText: answerText,
    createdAt: createdAt,
    isApproved: isApproved ?? this.isApproved,
  );

  @override
  List<Object?> get props => [
    id,
    questionId,
    responderUid,
    responderName,
    responderRole,
    answerText,
    createdAt,
    isApproved,
  ];
}
