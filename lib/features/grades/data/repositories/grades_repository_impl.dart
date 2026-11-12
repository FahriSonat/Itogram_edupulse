import '../../../../core/network/network_info.dart';
import '../../domain/entities/course_grade_entity.dart';
import '../../domain/repositories/grades_repository.dart';
import '../datasources/grades_remote_datasource.dart';
import '../models/course_grade_model.dart';

class GradesRepositoryImpl implements GradesRepository {
  final GradesRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  GradesRepositoryImpl({
    GradesRemoteDataSource? remoteDataSource,
    NetworkInfo? networkInfo,
  })  : _remoteDataSource = remoteDataSource ?? GradesRemoteDataSourceImpl(),
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  @override
  Stream<List<CourseGradeEntity>> watchStudentGrades(String studentUid) {
    return _remoteDataSource.watchStudentGrades(studentUid);
  }

  @override
  Stream<List<CourseGradeEntity>> watchCourseGrades(String courseId) {
    return _remoteDataSource.watchCourseGrades(courseId);
  }

  @override
  Future<void> manageStudentGrade(CourseGradeEntity grade) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final model = grade is CourseGradeModel
        ? grade
        : CourseGradeModel(
            gradeId:
                grade.gradeId.isNotEmpty ? grade.gradeId : grade.studentUid,
            courseId: grade.courseId,
            courseName: grade.courseName,
            credit: grade.credit,
            studentUid: grade.studentUid,
            studentName: grade.studentName,
            studentNo: grade.studentNo,
            midtermScore: grade.midtermScore,
            finalScore: grade.finalScore,
            bonusScore: grade.bonusScore,
            totalAverage: grade.totalAverage,
            letterGrade: grade.letterGrade,
          );

    await _remoteDataSource.manageStudentGrade(model);
  }

  @override
  Future<void> deleteStudentGrade(String gradeId, String courseId) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    await _remoteDataSource.deleteStudentGrade(gradeId, courseId);
  }

  @override
  Future<List<({String uid, String name, String studentNo})>> getRegisteredStudents() async {
    final raw = await _remoteDataSource.getRegisteredStudents();
    return raw
        .map((Map<String, dynamic> d) => (
              uid: (d['uid'] ?? '').toString(),
              name: (d['fullName'] ?? '').toString(),
              studentNo: (d['studentOrStaffNo'] ?? d['studentNo'] ?? '').toString(),
            ))
        .toList();
  }
}
