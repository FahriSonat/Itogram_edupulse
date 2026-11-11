import '../../../../core/network/network_info.dart';
import '../../domain/entities/course_schedule_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';
import '../models/course_schedule_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ScheduleRepositoryImpl({
    ScheduleRemoteDataSource? remoteDataSource,
    NetworkInfo? networkInfo,
  })  : _remoteDataSource = remoteDataSource ?? ScheduleRemoteDataSourceImpl(),
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  @override
  Stream<List<CourseScheduleEntity>> watchWeeklySchedule() {
    return _remoteDataSource.watchWeeklySchedule();
  }

  @override
  Future<void> addCourse(CourseScheduleEntity course) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final model = course is CourseScheduleModel
        ? course
        : CourseScheduleModel(
            courseId: course.courseId,
            courseCode: course.courseCode,
            courseName: course.courseName,
            instructorName: course.instructorName,
            roomLocation: course.roomLocation,
            dayOfWeek: course.dayOfWeek,
            startTime: course.startTime,
            endTime: course.endTime,
          );

    await _remoteDataSource.addCourse(model);
  }

  @override
  Future<void> updateCourse(CourseScheduleEntity course) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final model = course is CourseScheduleModel
        ? course
        : CourseScheduleModel(
            courseId: course.courseId,
            courseCode: course.courseCode,
            courseName: course.courseName,
            instructorName: course.instructorName,
            roomLocation: course.roomLocation,
            dayOfWeek: course.dayOfWeek,
            startTime: course.startTime,
            endTime: course.endTime,
          );

    await _remoteDataSource.updateCourse(model);
  }

  @override
  Future<void> removeCourse(String courseId) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }
    await _remoteDataSource.removeCourse(courseId);
  }
}
