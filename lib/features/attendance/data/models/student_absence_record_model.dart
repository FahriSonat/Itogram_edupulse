import '../../domain/entities/student_absence_record_entity.dart';

class StudentAbsenceRecordModel extends StudentAbsenceRecordEntity {
  const StudentAbsenceRecordModel({
    required super.id,
    required super.studentUid,
    required super.studentName,
    required super.studentNo,
    required super.courseId,
    required super.courseCode,
    required super.courseName,
    required super.absentHours,
    required super.totalHours,
  });

  factory StudentAbsenceRecordModel.fromEntity(StudentAbsenceRecordEntity e) => StudentAbsenceRecordModel(
    id: e.id,
    studentUid: e.studentUid,
    studentName: e.studentName,
    studentNo: e.studentNo,
    courseId: e.courseId,
    courseCode: e.courseCode,
    courseName: e.courseName,
    absentHours: e.absentHours,
    totalHours: e.totalHours,
  );

  factory StudentAbsenceRecordModel.fromJson(Map<String, dynamic> json) => StudentAbsenceRecordModel(
    id: json['id'] as String,
    studentUid: json['studentUid'] as String? ?? '',
    studentName: json['studentName'] as String? ?? '',
    studentNo: json['studentNo'] as String? ?? '',
    courseId: json['courseId'] as String? ?? '',
    courseCode: json['courseCode'] as String? ?? '',
    courseName: json['courseName'] as String? ?? '',
    absentHours: (json['absentHours'] as num?)?.toInt() ?? 0,
    totalHours: (json['totalHours'] as num?)?.toInt() ?? 40,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentUid': studentUid,
    'studentName': studentName,
    'studentNo': studentNo,
    'courseId': courseId,
    'courseCode': courseCode,
    'courseName': courseName,
    'absentHours': absentHours,
    'totalHours': totalHours,
  };
}
