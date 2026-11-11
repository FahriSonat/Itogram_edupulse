import '../../../../core/enums/letter_grade.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/grades_remote_datasource.dart';

class GradesRepositoryImpl {
  final GradesRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  GradesRepositoryImpl({
    GradesRemoteDataSource? remoteDataSource,
    NetworkInfo? networkInfo,
  })  : _remoteDataSource = remoteDataSource ?? GradesRemoteDataSourceImpl(),
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  /// Eğitmen için sisteme kayıtlı öğrencilerin listesini getirir
  Future<List<Map<String, dynamic>>> getRegisteredStudents({
    String? courseId,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }
    return _remoteDataSource.getRegisteredStudents(courseId: courseId);
  }

  Stream<List<Map<String, dynamic>>> watchCourseGrades(String courseId) {
    return _remoteDataSource.watchCourseGrades(courseId);
  }

  Stream<List<Map<String, dynamic>>> watchStudentGrades(String studentId) {
    return _remoteDataSource.watchStudentGrades(studentId);
  }

  /// Seçilen öğrencinin `courses/{courseId}/grades/{studentUid}` notunu kaydeder veya günceller
  Future<Map<String, dynamic>> manageStudentGrade({
    required String courseId,
    required String courseCode,
    required String courseName,
    required int credit,
    required String studentId,
    required String studentName,
    required String studentNo,
    double? midtermScore,
    double? finalScore,
    double? projectScore,
    double midtermWeight = 0.4,
    double finalWeight = 0.6,
    double projectWeight = 0.0,
    LetterGrade? letterGrade,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    return _remoteDataSource.upsertStudentGrade(
      courseId: courseId,
      courseCode: courseCode,
      courseName: courseName,
      credit: credit,
      studentId: studentId,
      studentName: studentName,
      studentNo: studentNo,
      midtermScore: midtermScore,
      finalScore: finalScore,
      projectScore: projectScore,
      midtermWeight: midtermWeight,
      finalWeight: finalWeight,
      projectWeight: projectWeight,
      letterGrade: letterGrade,
    );
  }

  /// Seçilen öğrencinin `courses/{courseId}/grades/{studentUid}` notunu siler
  Future<void> deleteStudentGrade({
    required String courseId,
    required String studentId,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    await _remoteDataSource.deleteStudentGrade(
      courseId: courseId,
      studentId: studentId,
    );
  }
}
