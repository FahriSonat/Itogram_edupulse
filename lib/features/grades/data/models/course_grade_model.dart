import '../../../../core/enums/letter_grade.dart';
import '../../domain/entities/course_grade_entity.dart';

class CourseGradeModel extends CourseGradeEntity {
  const CourseGradeModel({
    required super.id,
    required super.studentUid,
    required super.studentName,
    required super.studentNo,
    super.courseId,
    required super.courseCode,
    required super.courseName,
    required super.credit,
    required super.term,
    required super.midterm,
    required super.finalExam,
    required super.bonus,
    required super.total,
    required super.letterGrade,
    required super.updatedAt,
  });

  factory CourseGradeModel.fromEntity(CourseGradeEntity e) => CourseGradeModel(
    id: e.id,
    studentUid: e.studentUid,
    studentName: e.studentName,
    studentNo: e.studentNo,
    courseId: e.courseId,
    courseCode: e.courseCode,
    courseName: e.courseName,
    credit: e.credit,
    term: e.term,
    midterm: e.midterm,
    finalExam: e.finalExam,
    bonus: e.bonus,
    total: e.total,
    letterGrade: e.letterGrade,
    updatedAt: e.updatedAt,
  );

  factory CourseGradeModel.fromJson(Map<String, dynamic> json) => CourseGradeModel(
    id: json['id'] as String,
    studentUid: json['studentUid'] as String? ?? '',
    studentName: json['studentName'] as String? ?? '',
    studentNo: json['studentNo'] as String? ?? '',
    courseId: json['courseId'] as String?,
    courseCode: json['courseCode'] as String? ?? '',
    courseName: json['courseName'] as String? ?? '',
    credit: (json['credit'] as num?)?.toInt() ?? 0,
    term: json['term'] as String? ?? CourseGradeEntity.currentTerm,
    midterm: (json['midterm'] as num?)?.toDouble() ?? 0,
    finalExam: (json['finalExam'] as num?)?.toDouble() ?? 0,
    bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
    letterGrade: LetterGrade.fromJson(json['letterGrade'] as String?),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentUid': studentUid,
    'studentName': studentName,
    'studentNo': studentNo,
    'courseId': courseId,
    'courseCode': courseCode,
    'courseName': courseName,
    'credit': credit,
    'term': term,
    'midterm': midterm,
    'finalExam': finalExam,
    'bonus': bonus,
    'total': total,
    'letterGrade': letterGrade.toJson(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
