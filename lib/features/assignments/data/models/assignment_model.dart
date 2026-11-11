import '../../domain/entities/assignment_entity.dart';

class AssignmentModel extends AssignmentEntity {
  const AssignmentModel({
    required super.id,
    required super.courseName,
    required super.title,
    required super.description,
    required super.rubricCriteria,
    required super.dueDate,
    required super.createdByUid,
    required super.createdByName,
    required super.createdAt,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) => AssignmentModel(
    id: json['id'] as String,
    courseName: json['courseName'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    rubricCriteria: json['rubricCriteria'] as String? ?? '',
    dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
    createdByUid: json['createdByUid'] as String? ?? '',
    createdByName: json['createdByName'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseName': courseName,
    'title': title,
    'description': description,
    'rubricCriteria': rubricCriteria,
    'dueDate': dueDate.toIso8601String(),
    'createdByUid': createdByUid,
    'createdByName': createdByName,
    'createdAt': createdAt.toIso8601String(),
  };
}
