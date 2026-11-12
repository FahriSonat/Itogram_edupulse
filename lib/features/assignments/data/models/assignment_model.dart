import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/assignment_entity.dart';

class AssignmentModel extends AssignmentEntity {
  const AssignmentModel({
    required super.assignmentId,
    required super.courseId,
    required super.courseName,
    required super.title,
    required super.description,
    required super.rubricCriteria,
    required super.dueDate,
  });

  factory AssignmentModel.fromFirestore(Map<String, dynamic> json, String id) {
    final rawDue = json['dueDate'];
    final DateTime dueDate = switch (rawDue) {
      final Timestamp ts => ts.toDate(),
      final DateTime dt => dt,
      final String s => DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0),
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };
    return AssignmentModel(
      assignmentId: id,
      courseId: (json['courseId'] ?? '').toString(),
      courseName: (json['courseName'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      rubricCriteria: (json['rubricCriteria'] ?? '').toString(),
      dueDate: dueDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'title': title,
      'description': description,
      'rubricCriteria': rubricCriteria,
      'dueDate': Timestamp.fromDate(dueDate),
    };
  }

  AssignmentModel copyWith({
    String? assignmentId,
    String? courseId,
    String? courseName,
    String? title,
    String? description,
    String? rubricCriteria,
    DateTime? dueDate,
  }) {
    return AssignmentModel(
      assignmentId: assignmentId ?? this.assignmentId,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      title: title ?? this.title,
      description: description ?? this.description,
      rubricCriteria: rubricCriteria ?? this.rubricCriteria,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}