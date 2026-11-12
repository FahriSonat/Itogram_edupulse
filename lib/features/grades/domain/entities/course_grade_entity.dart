import 'package:equatable/equatable.dart';
import '../../../../core/enums/letter_grade.dart';

class CourseGradeEntity extends Equatable {
  final String gradeId;
  final String courseId;
  final String courseName;
  final int credit;
  final String studentUid;
  final String studentName;
  final String studentNo;
  final double? midtermScore;
  final double? finalScore;
  final double? bonusScore;
  final double? totalAverage;
  final LetterGrade? letterGrade;

  const CourseGradeEntity({
    required this.gradeId,
    required this.courseId,
    required this.courseName,
    required this.credit,
    required this.studentUid,
    required this.studentName,
    required this.studentNo,
    this.midtermScore,
    this.finalScore,
    this.bonusScore,
    this.totalAverage,
    this.letterGrade,
  });

  @override
  List<Object?> get props => [
        gradeId,
        courseId,
        courseName,
        credit,
        studentUid,
        studentName,
        studentNo,
        midtermScore,
        finalScore,
        bonusScore,
        totalAverage,
        letterGrade,
      ];
}