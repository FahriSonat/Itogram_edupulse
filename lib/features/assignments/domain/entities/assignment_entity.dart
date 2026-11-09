import 'package:equatable/equatable.dart';

class AssignmentEntity extends Equatable {
  final String assignmentId;
  final String courseId;
  final String courseName;
  final String title;
  final String description;
  final String rubricCriteria;
  final DateTime dueDate;

  const AssignmentEntity({
    required this.assignmentId,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.description,
    required this.rubricCriteria,
    required this.dueDate,
  });

  @override
  List<Object?> get props => [
        assignmentId,
        courseId,
        courseName,
        title,
        description,
        rubricCriteria,
        dueDate,
      ];
}