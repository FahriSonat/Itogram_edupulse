import '../../../../core/error/failures.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../domain/entities/course_grade_entity.dart';
import '../../domain/repositories/grades_repository.dart';
import '../datasources/grades_remote_datasource.dart';
import '../models/course_grade_model.dart';

class GradesRepositoryImpl implements GradesRepository {
  GradesRepositoryImpl({required this.remote, required this.notifications});

  final GradesRemoteDataSource remote;
  final NotificationService notifications;

  @override
  Stream<List<CourseGradeEntity>> watchGrades() => remote.watchGrades();

  @override
  List<CourseGradeEntity> getGrades() => remote.getGrades();

  @override
  Future<void> saveGrade(CourseGradeEntity grade) async {
    try {
      await remote.saveGrade(CourseGradeModel.fromEntity(grade));
      await notifications.send(
        title: 'Not bilgin güncellendi',
        body:
            '${grade.courseName}: Başarı notu ${grade.total.toStringAsFixed(1)} '
            '(${grade.letterGrade.name}).',
        kind: NotificationKind.grade,
        targetUid: grade.studentUid,
      );
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  Future<void> deleteGrade(String gradeId) async {
    try {
      await remote.deleteGrade(gradeId);
    } catch (e) {
      throw Failure.from(e);
    }
  }
}
