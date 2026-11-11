import 'package:equatable/equatable.dart';

import '../../../../core/enums/letter_grade.dart';

/// [CourseGradeEntity] öğrencinin bir dersteki vize, final, bonus ve başarı notu.
class CourseGradeEntity extends Equatable {
  /// Yeni girilen notların ait olduğu akademik dönem.
  static const String currentTerm = '2026-2027 Güz';

  final String id;
  final String studentUid;
  final String studentName;
  final String studentNo;
  final String? courseId;
  final String courseCode;
  final String courseName;
  final int credit;
  final String term;
  final double midterm;
  final double finalExam;
  final double bonus;

  /// (Vize * 0.40) + (Final * 0.60) + Bonus, en fazla 100.
  final double total;
  final LetterGrade letterGrade;
  final DateTime updatedAt;

  const CourseGradeEntity({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.studentNo,
    this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.credit,
    required this.term,
    required this.midterm,
    required this.finalExam,
    required this.bonus,
    required this.total,
    required this.letterGrade,
    required this.updatedAt,
  });

  /// Öğrenci + ders kodu + dönem için kalıcı (deterministik) kimlik.
  static String buildId(String studentUid, String courseCode, String term) {
    final termSlug = term.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return 'g_${studentUid}_${courseCode.toLowerCase()}_$termSlug';
  }

  bool get isCurrentTerm => term == currentTerm;

  @override
  List<Object?> get props => [
    id,
    studentUid,
    studentName,
    studentNo,
    courseId,
    courseCode,
    courseName,
    credit,
    term,
    midterm,
    finalExam,
    bonus,
    total,
    letterGrade,
    updatedAt,
  ];
}
