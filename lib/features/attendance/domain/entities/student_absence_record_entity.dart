import 'package:equatable/equatable.dart';

class StudentAbsenceRecordEntity extends Equatable {
  final String studentUid;
  final String studentName;
  final String studentNo;
  final String courseId;
  final String courseName;
  final int totalCourseHours;
  final int absentHours;
  final double absencePercentage;
  final bool isCriticalRisk;

  const StudentAbsenceRecordEntity({
    required this.studentUid,
    required this.studentName,
    required this.studentNo,
    required this.courseId,
    required this.courseName,
    required this.totalCourseHours,
    required this.absentHours,
    required this.absencePercentage,
    required this.isCriticalRisk,
  });

  @override
  List<Object?> get props => [
        studentUid,
        studentName,
        studentNo,
        courseId,
        courseName,
        totalCourseHours,
        absentHours,
        absencePercentage,
        isCriticalRisk,
      ];
}