import '../../domain/entities/student_absence_record_entity.dart';

class StudentAbsenceRecordModel extends StudentAbsenceRecordEntity {
  const StudentAbsenceRecordModel({
    required super.studentUid,
    required super.studentName,
    required super.studentNo,
    required super.courseId,
    required super.courseName,
    required super.totalCourseHours,
    required super.absentHours,
    required super.absencePercentage,
    required super.isCriticalRisk,
  });

  factory StudentAbsenceRecordModel.fromFirestore(Map<String, dynamic> json, String uid) {
    return StudentAbsenceRecordModel(
      studentUid: uid,
      studentName: json['studentName'] as String,
      studentNo: json['studentNo'] as String,
      courseId: json['courseId'] as String,
      courseName: json['courseName'] as String,
      totalCourseHours: json['totalCourseHours'] as int,
      absentHours: json['absentHours'] as int,
      absencePercentage: (json['absencePercentage'] as num).toDouble(),
      isCriticalRisk: json['isCriticalRisk'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentName': studentName,
      'studentNo': studentNo,
      'courseId': courseId,
      'courseName': courseName,
      'totalCourseHours': totalCourseHours,
      'absentHours': absentHours,
      'absencePercentage': absencePercentage,
      'isCriticalRisk': isCriticalRisk,
    };
  }

  StudentAbsenceRecordModel copyWith({
    String? studentUid,
    String? studentName,
    String? studentNo,
    String? courseId,
    String? courseName,
    int? totalCourseHours,
    int? absentHours,
    double? absencePercentage,
    bool? isCriticalRisk,
  }) {
    return StudentAbsenceRecordModel(
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      studentNo: studentNo ?? this.studentNo,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      totalCourseHours: totalCourseHours ?? this.totalCourseHours,
      absentHours: absentHours ?? this.absentHours,
      absencePercentage: absencePercentage ?? this.absencePercentage,
      isCriticalRisk: isCriticalRisk ?? this.isCriticalRisk,
    );
  }
}