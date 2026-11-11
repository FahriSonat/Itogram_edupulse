import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/course_grade_model.dart';

abstract class GradesRemoteDataSource {
  Stream<List<CourseGradeModel>> watchGrades();
  List<CourseGradeModel> getGrades();
  Future<void> saveGrade(CourseGradeModel grade);
  Future<void> deleteGrade(String id);
}

class LocalGradesRemoteDataSource implements GradesRemoteDataSource {
  LocalGradesRemoteDataSource(this._storage);

  final LocalStorageService _storage;

  @override
  Stream<List<CourseGradeModel>> watchGrades() =>
      _storage.watch(FirestorePaths.grades).map((docs) => docs.map(CourseGradeModel.fromJson).toList());

  @override
  List<CourseGradeModel> getGrades() => _storage.getAll(FirestorePaths.grades).map(CourseGradeModel.fromJson).toList();

  @override
  Future<void> saveGrade(CourseGradeModel grade) => _storage.upsert(FirestorePaths.grades, grade.toJson());

  @override
  Future<void> deleteGrade(String id) => _storage.delete(FirestorePaths.grades, id);
}
