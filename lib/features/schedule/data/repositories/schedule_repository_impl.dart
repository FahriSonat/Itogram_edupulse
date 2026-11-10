import '../../../../core/network/network_info.dart';
import '../datasources/schedule_remote_datasource.dart';

class ScheduleRepositoryImpl {
  final ScheduleRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ScheduleRepositoryImpl({
    ScheduleRemoteDataSource? remoteDataSource,
    NetworkInfo? networkInfo,
  })  : _remoteDataSource = remoteDataSource ?? ScheduleRemoteDataSourceImpl(),
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  Stream<List<Map<String, dynamic>>> watchWeeklySchedule({
    int? dayOfWeek,
    String? instructorId,
    String? studentId,
  }) {
    return _remoteDataSource.watchWeeklySchedule(
      dayOfWeek: dayOfWeek,
      instructorId: instructorId,
      studentId: studentId,
    );
  }

  Future<Map<String, dynamic>> addCourse({
    required String courseCode,
    required String courseName,
    required String instructorId,
    required String instructorName,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String classroom,
    int credit = 3,
    List<String> enrolledStudentIds = const [],
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    return _remoteDataSource.addCourseSchedule(
      courseCode: courseCode,
      courseName: courseName,
      instructorId: instructorId,
      instructorName: instructorName,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      classroom: classroom,
      credit: credit,
      enrolledStudentIds: enrolledStudentIds,
    );
  }

  /// Eğitmen ders saatini (`startTime`, `endTime`), amfi konumunu (`classroom`, örn: `D-107`)
  /// veya hoca adını (`instructorName`) güncellediğinde Firestore `courses` dökümanını günceller.
  Future<Map<String, dynamic>> updateCourseDetails({
    required String courseId,
    String? courseCode,
    String? courseName,
    String? instructorId,
    String? instructorName,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? classroom,
    int? credit,
    List<String>? enrolledStudentIds,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    return _remoteDataSource.updateCourseDetails(
      courseId: courseId,
      courseCode: courseCode,
      courseName: courseName,
      instructorId: instructorId,
      instructorName: instructorName,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      classroom: classroom,
      credit: credit,
      enrolledStudentIds: enrolledStudentIds,
    );
  }

  Future<void> removeCourse(String courseId) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }
    await _remoteDataSource.removeCourseSchedule(courseId);
  }
}
