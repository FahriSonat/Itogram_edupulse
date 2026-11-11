import '../entities/course_schedule_entity.dart';

abstract class ScheduleRepository {
  Stream<List<CourseScheduleEntity>> watchWeeklySchedule();

  Future<List<CourseScheduleEntity>> getCourses();

  /// `course.id` boşsa yeni ders oluşturulur, değilse güncellenir.
  Future<CourseScheduleEntity> saveCourse(CourseScheduleEntity course);

  Future<void> removeCourse(String courseId);
}
