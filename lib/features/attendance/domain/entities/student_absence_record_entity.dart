import 'package:equatable/equatable.dart';

/// [StudentAbsenceRecordEntity] bir öğrencinin bir dersteki dönemlik devamsızlığı.
///
/// Kural 3 (Devamsızlık Uyarı Motoru): devamsızlık oranı %20'ye ulaştığında
/// kayıt kritik sayılır ve öğrenciye uyarı gönderilir.
class StudentAbsenceRecordEntity extends Equatable {
  static const double criticalThreshold = 20.0;
  static const double warningThreshold = 15.0;

  final String id;
  final String studentUid;
  final String studentName;
  final String studentNo;
  final String courseId;
  final String courseCode;
  final String courseName;
  final int absentHours;
  final int totalHours;

  const StudentAbsenceRecordEntity({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.studentNo,
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.absentHours,
    required this.totalHours,
  });

  static String buildId(String studentUid, String courseId) => '${studentUid}_$courseId';

  double get percentage => totalHours <= 0 ? 0 : (absentHours / totalHours * 100).clamp(0, 100).toDouble();

  bool get isCritical => percentage >= criticalThreshold;

  bool get isWarning => !isCritical && percentage >= warningThreshold;

  StudentAbsenceRecordEntity copyWith({int? absentHours, int? totalHours}) => StudentAbsenceRecordEntity(
    id: id,
    studentUid: studentUid,
    studentName: studentName,
    studentNo: studentNo,
    courseId: courseId,
    courseCode: courseCode,
    courseName: courseName,
    absentHours: absentHours ?? this.absentHours,
    totalHours: totalHours ?? this.totalHours,
  );

  @override
  List<Object?> get props => [
    id,
    studentUid,
    studentName,
    studentNo,
    courseId,
    courseCode,
    courseName,
    absentHours,
    totalHours,
  ];
}
