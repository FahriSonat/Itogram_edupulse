import '../entities/course_schedule_entity.dart';

abstract class ScheduleRepository {
  Stream<List<CourseScheduleEntity>> watchWeeklySchedule();
  
  Future<void> addCourse(CourseScheduleEntity course);
  
  Future<void> updateCourse(CourseScheduleEntity course);
  
  Future<void> removeCourse(String courseId);
}