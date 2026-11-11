import '../../../../core/error/failures.dart';
import '../../domain/entities/course_schedule_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';
import '../models/course_schedule_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl(this._remote);

  final ScheduleRemoteDataSource _remote;

  @override
  Stream<List<CourseScheduleEntity>> watchWeeklySchedule() => _remote.watchCourses();

  @override
  Future<List<CourseScheduleEntity>> getCourses() async {
    try {
      return await _remote.getCourses();
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  Future<CourseScheduleEntity> saveCourse(CourseScheduleEntity course) async {
    try {
      final withId = course.id.isEmpty ? course.copyWith(id: _remote.newId()) : course;
      final model = CourseScheduleModel.fromEntity(withId);
      await _remote.upsertCourse(model);
      return model;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  Future<void> removeCourse(String courseId) async {
    try {
      await _remote.deleteCourse(courseId);
    } catch (e) {
      throw Failure.from(e);
    }
  }
}
