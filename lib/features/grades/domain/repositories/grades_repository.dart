import '../entities/course_grade_entity.dart';

abstract class GradesRepository {
  Stream<List<CourseGradeEntity>> watchGrades();

  List<CourseGradeEntity> getGrades();

  /// Notu kaydeder ve öğrenciye bildirim gönderir.
  Future<void> saveGrade(CourseGradeEntity grade);

  Future<void> deleteGrade(String gradeId);
}
