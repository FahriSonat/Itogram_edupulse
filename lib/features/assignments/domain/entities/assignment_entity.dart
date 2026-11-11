import 'package:equatable/equatable.dart';

/// [AssignmentEntity] eğitmenin yayınladığı ödev ve değerlendirme rubriği.
class AssignmentEntity extends Equatable {
  final String id;
  final String courseName;
  final String title;
  final String description;
  final String rubricCriteria;
  final DateTime dueDate;
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;

  const AssignmentEntity({
    required this.id,
    required this.courseName,
    required this.title,
    required this.description,
    required this.rubricCriteria,
    required this.dueDate,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
  });

  /// Kural 2: Son teslim tarihi geçti mi?
  bool isPastDue([DateTime? now]) => (now ?? DateTime.now()).isAfter(dueDate);

  @override
  List<Object?> get props => [
    id,
    courseName,
    title,
    description,
    rubricCriteria,
    dueDate,
    createdByUid,
    createdByName,
    createdAt,
  ];
}
