import '../../domain/entities/course_grade_entity.dart';
import '../../../../core/enums/letter_grade.dart';

class CourseGradeModel extends CourseGradeEntity {
  const CourseGradeModel({
    required super.gradeId,
    required super.courseId,
    required super.courseName,
    required super.credit,
    required super.studentUid,
    required super.studentName,
    required super.studentNo,
    super.midtermScore,
    super.finalScore,
    super.bonusScore,
    super.totalAverage,
    super.letterGrade,
  });

  factory CourseGradeModel.fromFirestore(Map<String, dynamic> json, String id) {
    return CourseGradeModel(
      gradeId: id,
      courseId: json['courseId'] as String,
      courseName: json['courseName'] as String,
      credit: json['credit'] as int,
      studentUid: json['studentUid'] as String,
      studentName: json['studentName'] as String,
      studentNo: json['studentNo'] as String,
      midtermScore: (json['midtermScore'] as num?)?.toDouble(),
      finalScore: (json['finalScore'] as num?)?.toDouble(),
      bonusScore: (json['bonusScore'] as num?)?.toDouble(),
      totalAverage: (json['totalAverage'] as num?)?.toDouble(),
      letterGrade: json['letterGrade'] != null
          ? LetterGrade.values.firstWhere(
              (e) => e.name == json['letterGrade'],
              orElse: () => LetterGrade.FF,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'credit': credit,
      'studentUid': studentUid,
      'studentName': studentName,
      'studentNo': studentNo,
      'midtermScore': midtermScore,
      'finalScore': finalScore,
      'bonusScore': bonusScore,
      'totalAverage': totalAverage,
      'letterGrade': letterGrade?.name,
    };
  }

  CourseGradeModel copyWith({
    String? gradeId,
    String? courseId,
    String? courseName,
    int? credit,
    String? studentUid,
    String? studentName,
    String? studentNo,
    double? midtermScore,
    double? finalScore,
    double? bonusScore,
    double? totalAverage,
    LetterGrade? letterGrade,
  }) {
    return CourseGradeModel(
      gradeId: gradeId ?? this.gradeId,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      credit: credit ?? this.credit,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      studentNo: studentNo ?? this.studentNo,
      midtermScore: midtermScore ?? this.midtermScore,
      finalScore: finalScore ?? this.finalScore,
      bonusScore: bonusScore ?? this.bonusScore,
      totalAverage: totalAverage ?? this.totalAverage,
      letterGrade: letterGrade ?? this.letterGrade,
    );
  }
}