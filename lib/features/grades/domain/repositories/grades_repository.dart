import '../entities/course_grade_entity.dart';

abstract class GradesRepository {
  Stream<List<CourseGradeEntity>> watchStudentGrades(String studentUid);
  
  Stream<List<CourseGradeEntity>> watchCourseGrades(String courseId);
  
  Future<void> manageStudentGrade(CourseGradeEntity grade);
  
  Future<void> deleteStudentGrade(String gradeId, String courseId);
}